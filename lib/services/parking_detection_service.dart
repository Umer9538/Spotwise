import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/parking_detection_model.dart';

/// Service for AI-powered parking space detection
class ParkingDetectionService {
  static const String baseUrl = 'https://847eeb17d886.ngrok-free.app';

  final ImagePicker _picker = ImagePicker();

  /// Convert any localhost:5001 URLs to ngrok URL for image display
  static String convertImageUrl(String url) {
    return url.replaceAll('http://localhost:5001', baseUrl)
              .replaceAll('localhost:5001', baseUrl)
              .replaceAll('https://9878e651e033.ngrok-free.app', baseUrl);
  }

  /// Capture image from camera
  Future<File?> captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Compress to reduce upload time
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;
      return File(photo.path);
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  /// Convert image file to base64 with data URI prefix
  Future<String> imageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to convert image to base64: $e');
    }
  }

  /// Convert image URL to base64 by downloading it first
  Future<String> imageUrlToBase64(String imageUrl) async {
    try {
      // Convert localhost URLs to ngrok URL
      final convertedUrl = convertImageUrl(imageUrl);
      debugPrint('🔗 Original URL: $imageUrl');
      debugPrint('🔗 Converted URL: $convertedUrl');
      
      final response = await http.get(
        Uri.parse(convertedUrl),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'User-Agent': 'SpotWise-App',
        },
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Image download timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to download image: HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (e) {
      throw Exception('Failed to download and convert image: $e');
    }
  }

  /// Send image to AI server for parking space detection
  Future<ParkingDetectionResponse> detectParkingSpots(File imageFile) async {
    try {
      // Convert image to base64
      final base64Image = await imageToBase64(imageFile);

      // Send POST request to AI server
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server took too long to respond (>30s)');
        },
      );

      // Check response status
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ParkingDetectionResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Bad request - invalid image data');
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Server error - model failed to process image');
      } else {
        throw Exception('Unexpected error: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'No internet connection or server not reachable.\n'
        'Make sure the AI server is running at: $baseUrl'
      );
    } on FormatException {
      throw Exception('Invalid response from server - not valid JSON');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Detection error: $e');
    }
  }

  /// Send image from URL to AI server for parking space detection
  Future<ParkingDetectionResponse> detectParkingSpotsFromUrl(String imageUrl) async {
    try {
      // Download image and convert to base64
      final base64Image = await imageUrlToBase64(imageUrl);

      // Send POST request to AI server
      final response = await http.post(
        Uri.parse('$baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - server took too long to respond (>30s)');
        },
      );

      // Check response status
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ParkingDetectionResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Bad request - invalid image data');
      } else if (response.statusCode == 500) {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] ?? 'Server error - model failed to process image');
      } else {
        throw Exception('Unexpected error: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'No internet connection or server not reachable.\n'
        'Make sure the AI server is running at: $baseUrl'
      );
    } on FormatException {
      throw Exception('Invalid response from server - not valid JSON');
    } on HttpException {
      throw Exception('HTTP error occurred');
    } catch (e) {
      if (e.toString().contains('timeout')) {
        rethrow;
      }
      throw Exception('Detection error: $e');
    }
  }

  /// Check if the AI server is online and responding
  Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test_images_list'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get list of test images available on server
  Future<List<String>> getTestImagesList() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test_images_list'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['images'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get server status information
  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final isOnline = await checkServerHealth();
      final testImages = isOnline ? await getTestImagesList() : <String>[];

      return {
        'online': isOnline,
        'url': baseUrl,
        'test_images_count': testImages.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'online': false,
        'url': baseUrl,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}
