import 'package:cloud_firestore/cloud_firestore.dart';

class DetectionResults {
  final int totalSpots;
  final int availableSpots;
  final int occupiedSpots;
  final DateTime detectedAt;
  final String? annotatedImageBase64; // Cached annotated image
  final List<Map<String, dynamic>>? freeSpotsData; // Cached free spots coordinates

  DetectionResults({
    required this.totalSpots,
    required this.availableSpots,
    required this.occupiedSpots,
    required this.detectedAt,
    this.annotatedImageBase64,
    this.freeSpotsData,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalSpots': totalSpots,
      'availableSpots': availableSpots,
      'occupiedSpots': occupiedSpots,
      'detectedAt': Timestamp.fromDate(detectedAt),
      'annotatedImageBase64': annotatedImageBase64,
      'freeSpotsData': freeSpotsData,
    };
  }

  factory DetectionResults.fromJson(Map<String, dynamic> json) {
    return DetectionResults(
      totalSpots: json['totalSpots'] as int,
      availableSpots: json['availableSpots'] as int,
      occupiedSpots: json['occupiedSpots'] as int,
      detectedAt: (json['detectedAt'] as Timestamp).toDate(),
      annotatedImageBase64: json['annotatedImageBase64'] as String?,
      freeSpotsData: json['freeSpotsData'] != null
          ? List<Map<String, dynamic>>.from(json['freeSpotsData'])
          : null,
    );
  }
}

class ParkingImageModel {
  final String imageId;
  final String parkingLotName;
  final String imageUrl;
  final String zoneId;
  final String? description;
  final DateTime uploadedAt;
  final DetectionResults? cachedResults;

  ParkingImageModel({
    required this.imageId,
    required this.parkingLotName,
    required this.imageUrl,
    required this.zoneId,
    this.description,
    required this.uploadedAt,
    this.cachedResults,
  });

  // Check if cached results are still valid (less than 5 minutes old)
  bool get hasValidCache {
    if (cachedResults == null) return false;
    final age = DateTime.now().difference(cachedResults!.detectedAt);
    return age.inMinutes < 5;
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'parkingLotName': parkingLotName,
      'imageUrl': imageUrl,
      'zoneId': zoneId,
      'description': description,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'cachedResults': cachedResults?.toJson(),
    };
  }

  factory ParkingImageModel.fromJson(Map<String, dynamic> json) {
    return ParkingImageModel(
      imageId: json['imageId'] as String? ?? '',
      parkingLotName: json['parkingLotName'] as String? ?? 'Unknown',
      imageUrl: json['imageUrl'] as String? ?? '',
      zoneId: json['zoneId'] as String? ?? '',
      description: json['description'] as String?,
      uploadedAt: json['uploadedAt'] != null
          ? (json['uploadedAt'] as Timestamp).toDate()
          : DateTime.now(),
      cachedResults: json['cachedResults'] != null
          ? DetectionResults.fromJson(json['cachedResults'] as Map<String, dynamic>)
          : null,
    );
  }

  factory ParkingImageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingImageModel.fromJson(data);
  }

  ParkingImageModel copyWith({
    String? imageId,
    String? parkingLotName,
    String? imageUrl,
    String? zoneId,
    String? description,
    DateTime? uploadedAt,
    DetectionResults? cachedResults,
  }) {
    return ParkingImageModel(
      imageId: imageId ?? this.imageId,
      parkingLotName: parkingLotName ?? this.parkingLotName,
      imageUrl: imageUrl ?? this.imageUrl,
      zoneId: zoneId ?? this.zoneId,
      description: description ?? this.description,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      cachedResults: cachedResults ?? this.cachedResults,
    );
  }
}
