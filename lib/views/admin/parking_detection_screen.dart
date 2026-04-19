import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/parking_detection_service.dart';
import '../../services/zone_service.dart';
import '../../models/parking_detection_model.dart';
import '../../models/parking_spot_model.dart';
import '../../providers/auth_provider.dart';

class ParkingDetectionScreen extends StatefulWidget {
  final String? zoneId; // Optional: to update specific zone
  final String? zoneName;

  const ParkingDetectionScreen({
    Key? key,
    this.zoneId,
    this.zoneName,
  }) : super(key: key);

  @override
  State<ParkingDetectionScreen> createState() => _ParkingDetectionScreenState();
}

class _ParkingDetectionScreenState extends State<ParkingDetectionScreen> {
  final ParkingDetectionService _detectionService = ParkingDetectionService();
  final ZoneService _zoneService = ZoneService();

  File? _capturedImage;
  ParkingDetectionResponse? _detectionResult;
  bool _isLoading = false;
  bool _isUpdatingFirestore = false;
  String? _error;
  bool _isServerOnline = false;

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final isOnline = await _detectionService.checkServerHealth();
    setState(() {
      _isServerOnline = isOnline;
    });

    if (!isOnline && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ AI Server is offline. Make sure Python server is running.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _captureAndDetect() async {
    if (!_isServerOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot capture: AI Server is offline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _detectionResult = null;
      _capturedImage = null;
    });

    try {
      // Step 1: Capture image
      final image = await _detectionService.captureImage();
      if (image == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _capturedImage = image;
      });

      // Step 2: Detect parking spots
      final result = await _detectionService.detectParkingSpots(image);

      setState(() {
        _detectionResult = result;
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Detected ${result.statistics.totalFreeSpots} free spots, '
              '${result.statistics.totalOccupiedSpots} occupied spots',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_isServerOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot pick image: AI Server is offline'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _detectionResult = null;
      _capturedImage = null;
    });

    try {
      final image = await _detectionService.pickImageFromGallery();
      if (image == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _capturedImage = image;
      });

      final result = await _detectionService.detectParkingSpots(image);

      setState(() {
        _detectionResult = result;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Detected ${result.statistics.totalFreeSpots} free spots',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updateFirestore() async {
    if (_detectionResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No detection results to update'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (widget.zoneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No zone selected. Please select a zone first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Database?'),
        content: Text(
          'This will update ${_detectionResult!.statistics.totalSpots} parking spots in ${widget.zoneName ?? "this zone"}.\n\n'
          'Free spots: ${_detectionResult!.statistics.totalFreeSpots}\n'
          'Occupied spots: ${_detectionResult!.statistics.totalOccupiedSpots}\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdatingFirestore = true);

    try {
      final zoneId = widget.zoneId!;
      final result = _detectionResult!;

      // Get all spots in this zone
      final spots = await _zoneService.getSpotsByZone(zoneId);

      if (spots.isEmpty) {
        throw Exception('No spots found in this zone');
      }

      // Update spots based on detection results
      // Strategy: Update first N spots as free, next M as occupied
      int updatedCount = 0;
      final totalDetected = result.statistics.totalFreeSpots +
                           result.statistics.totalOccupiedSpots;

      for (int i = 0; i < spots.length && i < totalDetected; i++) {
        SpotStatus newStatus;

        if (i < result.statistics.totalFreeSpots) {
          newStatus = SpotStatus.available;
        } else {
          newStatus = SpotStatus.occupied;
        }

        // Only update if status changed
        if (spots[i].status != newStatus) {
          await _zoneService.updateSpotStatus(
            zoneId: zoneId,
            spotId: spots[i].spotId,
            status: newStatus,
          );
          updatedCount++;
        }
      }

      setState(() => _isUpdatingFirestore = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Successfully updated $updatedCount spots in Firestore'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after successful update
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() => _isUpdatingFirestore = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Update failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Parking Detection', style: TextStyle(fontSize: 18)),
            if (widget.zoneName != null)
              Text(
                widget.zoneName!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isServerOnline ? Icons.cloud_done : Icons.cloud_off,
              color: _isServerOnline ? Colors.green : Colors.red,
            ),
            onPressed: _checkServer,
            tooltip: _isServerOnline ? 'Server Online' : 'Server Offline - Tap to retry',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server Status Card
            _buildServerStatusCard(),

            const SizedBox(height: 16),

            // Instructions Card
            _buildInstructionsCard(),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _isUpdatingFirestore) ? null : _captureAndDetect,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Photo'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || _isUpdatingFirestore) ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loading Indicator
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Analyzing parking lot with AI...'),
                    SizedBox(height: 4),
                    Text(
                      'This may take 5-10 seconds',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Updating Firestore Indicator
            if (_isUpdatingFirestore)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Updating parking spots in Firestore...'),
                  ],
                ),
              ),

            // Error Display
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Error',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ],
                  ),
                ),
              ),

            // Results Display
            if (_detectionResult != null && !_isLoading) ...[
              const SizedBox(height: 16),
              _buildResultsSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServerStatusCard() {
    return Card(
      color: _isServerOnline ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isServerOnline ? Icons.check_circle : Icons.error,
              color: _isServerOnline ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isServerOnline ? 'AI Server is Online' : 'AI Server is Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isServerOnline ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  if (!_isServerOnline) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Start server: python server.py',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'How to use:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text('1. Take an aerial/elevated photo of the parking lot'),
            SizedBox(height: 4),
            Text('2. AI will detect all parking spots automatically'),
            SizedBox(height: 4),
            Text('3. Review results (Green = Free, Red = Occupied)'),
            SizedBox(height: 4),
            Text('4. Tap "Update Database" to save to Firestore'),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final result = _detectionResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Statistics Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detection Results',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'Free Spots',
                      result.statistics.totalFreeSpots.toString(),
                      Colors.green,
                      Icons.local_parking,
                    ),
                    _buildStatCard(
                      'Occupied',
                      result.statistics.totalOccupiedSpots.toString(),
                      Colors.red,
                      Icons.block,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: result.statistics.freePercentage / 100,
                  backgroundColor: Colors.red.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.statistics.freePercentage.toStringAsFixed(1)}% Available',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Result Image with Overlay
        const Text(
          'Visual Result (Green=Free, Red=Occupied):',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(result.resultImage.split(',')[1]),
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 20),

        // Update Database Button
        ElevatedButton.icon(
          onPressed: _isUpdatingFirestore ? null : _updateFirestore,
          icon: _isUpdatingFirestore
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.cloud_upload),
          label: Text(_isUpdatingFirestore ? 'Updating...' : 'Update Firestore Database'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(16),
          ),
        ),

        if (widget.zoneId == null)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '⚠️ No zone selected. Select a zone to update database.',
              style: TextStyle(color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Parking Detection Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How it works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. The AI model analyzes parking lot images'),
              Text('2. Detects individual parking spots'),
              Text('3. Classifies each as free or occupied'),
              Text('4. Returns coordinates and statistics'),
              SizedBox(height: 16),
              Text(
                'Best practices:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Take photo from elevated angle'),
              Text('• Ensure good lighting'),
              Text('• Capture entire parking zone'),
              Text('• Keep camera stable'),
              SizedBox(height: 16),
              Text(
                'Server requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Python server must be running'),
              Text('• Command: python server.py'),
              Text('• Default port: 5000'),
              Text('• Response time: 5-10 seconds'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
