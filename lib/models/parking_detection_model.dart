/// Model for AI parking detection response
class ParkingDetectionResponse {
  final bool success;
  final String resultImage;
  final ParkingStatistics statistics;
  final List<DetectedSpot> freeSpots;
  final List<DetectedSpot> occupiedSpots;

  ParkingDetectionResponse({
    required this.success,
    required this.resultImage,
    required this.statistics,
    required this.freeSpots,
    required this.occupiedSpots,
  });

  factory ParkingDetectionResponse.fromJson(Map<String, dynamic> json) {
    return ParkingDetectionResponse(
      success: json['success'] ?? false,
      resultImage: json['result_image'] ?? '',
      statistics: ParkingStatistics.fromJson(json['statistics'] ?? {}),
      freeSpots: (json['free_spots'] as List? ?? [])
          .map((spot) => DetectedSpot.fromJson(spot as Map<String, dynamic>))
          .toList(),
      occupiedSpots: (json['occupied_spots'] as List? ?? [])
          .map((spot) => DetectedSpot.fromJson(spot as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'result_image': resultImage,
      'statistics': statistics.toJson(),
      'free_spots': freeSpots.map((spot) => spot.toJson()).toList(),
      'occupied_spots': occupiedSpots.map((spot) => spot.toJson()).toList(),
    };
  }
}

/// Statistics about detected parking spaces
class ParkingStatistics {
  final int freePixels;
  final int occupiedPixels;
  final double freePercentage;
  final double occupiedPercentage;
  final int totalFreeSpots;
  final int totalOccupiedSpots;

  ParkingStatistics({
    required this.freePixels,
    required this.occupiedPixels,
    required this.freePercentage,
    required this.occupiedPercentage,
    required this.totalFreeSpots,
    required this.totalOccupiedSpots,
  });

  factory ParkingStatistics.fromJson(Map<String, dynamic> json) {
    return ParkingStatistics(
      freePixels: json['free_pixels'] ?? 0,
      occupiedPixels: json['occupied_pixels'] ?? 0,
      freePercentage: (json['free_percentage'] ?? 0.0).toDouble(),
      occupiedPercentage: (json['occupied_percentage'] ?? 0.0).toDouble(),
      totalFreeSpots: json['total_free_spots'] ?? 0,
      totalOccupiedSpots: json['total_occupied_spots'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'free_pixels': freePixels,
      'occupied_pixels': occupiedPixels,
      'free_percentage': freePercentage,
      'occupied_percentage': occupiedPercentage,
      'total_free_spots': totalFreeSpots,
      'total_occupied_spots': totalOccupiedSpots,
    };
  }

  /// Get total detected spots
  int get totalSpots => totalFreeSpots + totalOccupiedSpots;

  /// Check if there are any free spots
  bool get hasFreeSpots => totalFreeSpots > 0;

  /// Check if parking is mostly full (>80% occupied)
  bool get isMostlyFull => occupiedPercentage > 80.0;

  /// Check if parking is mostly empty (>80% free)
  bool get isMostlyEmpty => freePercentage > 80.0;
}

/// Detected parking spot with coordinates
class DetectedSpot {
  final int x;
  final int y;
  final int width;
  final int height;
  final int centerX;
  final int centerY;
  final int area;

  DetectedSpot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.centerX,
    required this.centerY,
    required this.area,
  });

  factory DetectedSpot.fromJson(Map<String, dynamic> json) {
    return DetectedSpot(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
      centerX: json['center_x'] ?? 0,
      centerY: json['center_y'] ?? 0,
      area: json['area'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'center_x': centerX,
      'center_y': centerY,
      'area': area,
    };
  }

  /// Get bounding rectangle
  Map<String, int> get boundingRect {
    return {
      'left': x,
      'top': y,
      'right': x + width,
      'bottom': y + height,
    };
  }

  /// Get center as a map
  Map<String, int> get center {
    return {
      'x': centerX,
      'y': centerY,
    };
  }

  /// Calculate distance from a point to this spot's center
  double distanceFrom(int pointX, int pointY) {
    final dx = centerX - pointX;
    final dy = centerY - pointY;
    return (dx * dx + dy * dy).toDouble();
  }
}
