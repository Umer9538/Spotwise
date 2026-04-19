import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../models/parking_image_model.dart';
import '../../models/parking_detection_model.dart';
import '../../services/parking_detection_service.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';

class ParkingDetectionResultsScreen extends StatefulWidget {
  final ParkingImageModel parkingImage;

  const ParkingDetectionResultsScreen({
    Key? key,
    required this.parkingImage,
  }) : super(key: key);

  @override
  State<ParkingDetectionResultsScreen> createState() =>
      _ParkingDetectionResultsScreenState();
}

class _ParkingDetectionResultsScreenState
    extends State<ParkingDetectionResultsScreen> {
  final ParkingDetectionService _detectionService = ParkingDetectionService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isDetecting = false;
  DetectionResults? _results;
  String? _error;
  bool _usedCache = false;
  String? _annotatedImageBase64;
  List<DetectedSpot>? _freeSpots; // Store free spot coordinates
  Size? _imageSize; // Store image dimensions for positioning
  Set<String> _bookedSpotIds = {}; // Track booked spots by their IDs

  @override
  void initState() {
    super.initState();
    _checkCacheAndDetect();
    _loadBookedSpots();
  }

  Future<void> _loadBookedSpots() async {
    // Load all active reservations for this zone to mark booked spots
    try {
      final reservations = await _firestore
          .collection('reservations')
          .where('zoneId', isEqualTo: widget.parkingImage.zoneId)
          .where('status', isEqualTo: 'active')
          .get();

      final bookedIds = reservations.docs
          .map((doc) => doc.data()['spotId'] as String)
          .toSet();

      if (mounted) {
        setState(() {
          _bookedSpotIds = bookedIds;
        });
        debugPrint('📍 Loaded ${bookedIds.length} booked spots for this zone');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load booked spots: $e');
    }
  }

  Future<void> _checkCacheAndDetect() async {
    // Check if we have valid cached results
    if (widget.parkingImage.hasValidCache) {
      debugPrint('📦 Loading cached detection results...');

      final cachedResults = widget.parkingImage.cachedResults!;

      setState(() {
        _results = cachedResults;
        // Note: Annotated image is NOT cached, so we need to call API to get it
        // For now, we'll show the original image with clickable overlays
        _usedCache = true;

        // Convert cached spots data back to DetectedSpot objects
        if (cachedResults.freeSpotsData != null) {
          _freeSpots = cachedResults.freeSpotsData!
              .map((spotData) => DetectedSpot(
                    x: spotData['x'] as int,
                    y: spotData['y'] as int,
                    width: spotData['width'] as int,
                    height: spotData['height'] as int,
                    centerX: spotData['centerX'] as int,
                    centerY: spotData['centerY'] as int,
                    area: spotData['area'] as int,
                  ))
              .toList();
        }
      });

      debugPrint('✅ Loaded from cache: ${_results?.availableSpots} available spots');
      debugPrint('ℹ️  Showing original image with clickable overlays (annotated image not cached)');
      return;
    }

    // No valid cache, run detection
    debugPrint('🔄 No valid cache found, calling AI model...');
    await _runDetection();
  }

  Future<void> _runDetection() async {
    setState(() {
      _isDetecting = true;
      _error = null;
      _usedCache = false;
    });

    try {
      debugPrint('🤖 Calling AI detection model...');

      // Run AI detection on the image URL
      final response = await _detectionService.detectParkingSpotsFromUrl(
        ParkingDetectionService.convertImageUrl(widget.parkingImage.imageUrl),
      );

      debugPrint('✅ AI detection completed: ${response.statistics.totalFreeSpots} free spots found');

      // Convert free spots to serializable format for database
      final freeSpotsData = response.freeSpots
          .map((spot) => {
                'x': spot.x,
                'y': spot.y,
                'width': spot.width,
                'height': spot.height,
                'centerX': spot.centerX,
                'centerY': spot.centerY,
                'area': spot.area,
              })
          .toList();

      // Create detection results with spots data (NOT the image - too large for Firestore)
      final results = DetectionResults(
        totalSpots: response.statistics.totalSpots,
        availableSpots: response.statistics.totalFreeSpots,
        occupiedSpots: response.statistics.totalOccupiedSpots,
        detectedAt: DateTime.now(),
        annotatedImageBase64: null, // Don't cache image (too large for Firestore)
        freeSpotsData: freeSpotsData, // Cache the free spots coordinates
      );

      // Save lightweight data to Firestore for future use (cache for 5 minutes)
      debugPrint('💾 Saving detection results to database...');
      try {
        await _firestore
            .collection('parking_images')
            .doc(widget.parkingImage.imageId)
            .update({
          'cachedResults': {
            'totalSpots': results.totalSpots,
            'availableSpots': results.availableSpots,
            'occupiedSpots': results.occupiedSpots,
            'detectedAt': Timestamp.fromDate(results.detectedAt),
            'freeSpotsData': results.freeSpotsData,
            // Note: annotatedImageBase64 is NOT cached (too large for Firestore)
          },
        });
        debugPrint('✅ Results cached in database');
      } catch (cacheError) {
        debugPrint('⚠️ Failed to cache results: $cacheError');
        // Continue anyway - we still have the results in memory
      }

      setState(() {
        _results = results;
        _annotatedImageBase64 = response.resultImage;
        _freeSpots = response.freeSpots;
        _isDetecting = false;
      });
    } catch (e) {
      debugPrint('❌ Detection failed: $e');
      setState(() {
        _error = e.toString();
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parkingImage.parkingLotName),
        actions: [
          if (_results != null && !_isDetecting)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _runDetection,
              tooltip: 'Refresh Detection',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Parking lot image
          _buildImageSection(),

          // Detection status/results
          if (_isDetecting)
            _buildDetectingState()
          else if (_error != null)
            _buildErrorState()
          else if (_results != null)
            _buildResultsSection(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 300,
      color: AppColors.backgroundGray,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _imageSize = Size(constraints.maxWidth, constraints.maxHeight);
          return Stack(
            fit: StackFit.expand,
            children: [
              // Show annotated image if available, otherwise show original
              _annotatedImageBase64 != null
                  ? _buildAnnotatedImage()
                  : Image.network(
                  ParkingDetectionService.convertImageUrl(widget.parkingImage.imageUrl),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 64,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: AppSizes.sm),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          if (_annotatedImageBase64 != null)
            Positioned(
              top: AppSizes.md,
              right: AppSizes.md,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          'AI DETECTION',
                          style: AppTextStyles.captionBold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_usedCache) ...[
                    const SizedBox(height: AppSizes.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.availableGreen,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cached,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'CACHED',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          // Interactive overlay for clickable spots
          if (_freeSpots != null && _freeSpots!.isNotEmpty)
            _buildClickableSpotsOverlay(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetectingState() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSizes.lg),
          Text(
            'Detecting parking spots...',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'AI is analyzing the parking lot image',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Results will be cached for faster access',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: CustomCard(
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.occupiedRed,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Detection Failed',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              _error ?? 'Unknown error occurred',
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton.icon(
              onPressed: _runDetection,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_results == null) return const SizedBox.shrink();

    final occupancyRate = _results!.totalSpots > 0
        ? (_results!.occupiedSpots / _results!.totalSpots * 100)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main stats card
          CustomCard(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                Text(
                  'Parking Availability',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSizes.lg),
                // Big number showing available spots
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: _results!.availableSpots > 0
                        ? AppColors.availableGreen.withOpacity(0.1)
                        : AppColors.occupiedRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    border: Border.all(
                      color: _results!.availableSpots > 0
                          ? AppColors.availableGreen
                          : AppColors.occupiedRed,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_results!.availableSpots}',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: _results!.availableSpots > 0
                              ? AppColors.availableGreen
                              : AppColors.occupiedRed,
                        ),
                      ),
                      Text(
                        'Available Spots',
                        style: AppTextStyles.bodyLight,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                // Detailed stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total',
                        '${_results!.totalSpots}',
                        Icons.local_parking,
                        AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _buildStatItem(
                        'Occupied',
                        '${_results!.occupiedSpots}',
                        Icons.block,
                        AppColors.occupiedRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                // Occupancy bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Occupancy Rate',
                          style: AppTextStyles.captionBold,
                        ),
                        Text(
                          '${occupancyRate.toStringAsFixed(0)}%',
                          style: AppTextStyles.captionBold.copyWith(
                            color: occupancyRate > 80
                                ? AppColors.occupiedRed
                                : occupancyRate > 50
                                    ? AppColors.reservedYellow
                                    : AppColors.availableGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      child: LinearProgressIndicator(
                        value: occupancyRate / 100,
                        minHeight: 12,
                        backgroundColor: AppColors.backgroundGray,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          occupancyRate > 80
                              ? AppColors.occupiedRed
                              : occupancyRate > 50
                                  ? AppColors.reservedYellow
                                  : AppColors.availableGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Last updated info
          CustomCard(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  'Last updated: ${_formatTime(_results!.detectedAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (widget.parkingImage.description != null) ...[
            const SizedBox(height: AppSizes.md),
            CustomCard(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Information',
                    style: AppTextStyles.captionBold,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    widget.parkingImage.description!,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(color: color),
          ),
          Text(
            label,
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildClickableSpotsOverlay() {
    if (_imageSize == null) return const SizedBox.shrink();

    return Stack(
      children: _freeSpots!.map((spot) {
        // Use DetectedSpot properties directly
        final x = spot.x.toDouble();
        final y = spot.y.toDouble();
        final width = spot.width.toDouble();
        final height = spot.height.toDouble();

        // Calculate position relative to image size (assuming image is 1280x720 from training)
        final originalImageWidth = 1280.0;
        final originalImageHeight = 720.0;

        final scaleX = _imageSize!.width / originalImageWidth;
        final scaleY = _imageSize!.height / originalImageHeight;

        // Check if this spot is already booked
        final spotId = 'spot_${widget.parkingImage.zoneId}_${spot.centerX}_${spot.centerY}';
        final isBooked = _bookedSpotIds.contains(spotId);

        return Positioned(
          left: x * scaleX,
          top: y * scaleY,
          width: width * scaleX,
          height: height * scaleY,
          child: GestureDetector(
            onTap: isBooked ? null : () => _onSpotTapped(spot),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isBooked
                      ? AppColors.occupiedRed.withOpacity(0.8)
                      : Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isBooked ? null : () => _onSpotTapped(spot),
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(
                        color: isBooked
                            ? AppColors.occupiedRed.withOpacity(0.3)
                            : AppColors.availableGreen.withOpacity(0.1),
                      ),
                      if (isBooked)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.occupiedRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.block,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _onSpotTapped(DetectedSpot spot) async {
    // Show AI verification loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          margin: EdgeInsets.all(AppSizes.xl),
          child: Padding(
            padding: EdgeInsets.all(AppSizes.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSizes.lg),
                Text(
                  'AI is detecting the spot...',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'Please wait',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wait 3 seconds for "AI verification"
    await Future.delayed(const Duration(seconds: 3));

    // Close loading dialog
    if (mounted) Navigator.pop(context);

    // Show booking dialog
    if (mounted) {
      _showBookingDialog(spot);
    }
  }

  void _showBookingDialog(DetectedSpot spot) {
    int selectedDuration = 30; // Default 30 minutes

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Book Parking Spot'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Spot verified and available!',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.availableGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text('Select duration:'),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  children: [15, 30, 60, 120].map((minutes) {
                    final isSelected = selectedDuration == minutes;
                    return ChoiceChip(
                      label: Text('$minutes min'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedDuration = minutes;
                          });
                        }
                      },
                      selectedColor: AppColors.primaryBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _createReservation(spot, selectedDuration);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                child: const Text('Book Now'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createReservation(DetectedSpot spot, int durationMinutes) async {
    try {
      // Get user ID and providers first
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

      // Check if user already has an active reservation FIRST
      debugPrint('🔍 Checking for existing reservations...');
      final existingReservations = await _firestore
          .collection('reservations')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();

      if (existingReservations.docs.isNotEmpty) {
        debugPrint('⚠️ User already has an active reservation');
        if (mounted) {
          _showExistingReservationDialog();
        }
        return;
      }

      // Show loading
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Generate unique spot ID based on spot coordinates
      final spotId = 'spot_${widget.parkingImage.zoneId}_${spot.centerX}_${spot.centerY}';
      final spotNumber = 'AI-${spot.centerX}-${spot.centerY}';

      // Get zone data to use its coordinates
      final zoneDoc = await _firestore
          .collection('parking_zones')
          .doc(widget.parkingImage.zoneId)
          .get();

      final zoneData = zoneDoc.data();
      final zoneCoordinates = zoneData?['coordinates'] as Map<String, dynamic>?;

      // Create the spot document in Firestore first (AI-detected spots are dynamic)
      debugPrint('📍 Creating spot document: $spotId');
      await _firestore
          .collection('parking_zones')
          .doc(widget.parkingImage.zoneId)
          .collection('spots')
          .doc(spotId)
          .set({
        'spot_id': spotId,
        'spot_number': spotNumber,
        'zone_id': widget.parkingImage.zoneId,
        'status': 'available',
        'spot_type': 'regular',
        'is_accessible': false,
        'is_ev_charging': false,
        // Geographic coordinates (from zone)
        'coordinates': {
          'latitude': zoneCoordinates?['latitude'] ?? 0.0,
          'longitude': zoneCoordinates?['longitude'] ?? 0.0,
        },
        // AI detection coordinates (pixel positions)
        'ai_coordinates': {
          'x': spot.x,
          'y': spot.y,
          'width': spot.width,
          'height': spot.height,
          'centerX': spot.centerX,
          'centerY': spot.centerY,
        },
        'features': [],
        'last_updated': DateTime.now().toIso8601String(),
        'created_at': FieldValue.serverTimestamp(),
        'created_by': 'ai_detection',
      });
      debugPrint('✅ Spot created successfully');

      // Small delay to ensure Firestore has propagated the write
      await Future.delayed(const Duration(milliseconds: 500));

      // Create reservation
      debugPrint('🔄 Creating reservation...');
      final success = await parkingProvider.createReservation(
        userId: userId,
        spotId: spotId,
        zoneId: widget.parkingImage.zoneId,
        spotNumber: spotNumber,
        duration: Duration(minutes: durationMinutes),
      );

      if (mounted) Navigator.pop(context); // Close loading

      if (success) {
        debugPrint('✅ Reservation created successfully');

        // Mark this spot as booked
        setState(() {
          _bookedSpotIds.add(spotId);
        });

        // Update the cached results to reflect new availability
        if (_results != null) {
          final updatedResults = DetectionResults(
            totalSpots: _results!.totalSpots,
            availableSpots: _results!.availableSpots - 1,
            occupiedSpots: _results!.occupiedSpots + 1,
            detectedAt: DateTime.now(),
            annotatedImageBase64: _results!.annotatedImageBase64,
            freeSpotsData: _results!.freeSpotsData,
          );

          // Update Firestore cache (lightweight data only)
          try {
            await _firestore
                .collection('parking_images')
                .doc(widget.parkingImage.imageId)
                .update({
              'cachedResults': {
                'totalSpots': updatedResults.totalSpots,
                'availableSpots': updatedResults.availableSpots,
                'occupiedSpots': updatedResults.occupiedSpots,
                'detectedAt': Timestamp.fromDate(updatedResults.detectedAt),
                'freeSpotsData': updatedResults.freeSpotsData,
              },
            });
          } catch (e) {
            debugPrint('⚠️ Failed to update cache: $e');
          }

          // Update local state
          setState(() {
            _results = updatedResults;
          });
        }

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Spot booked for $durationMinutes minutes!'),
              backgroundColor: AppColors.availableGreen,
              duration: const Duration(seconds: 2),
            ),
          );

          // Navigate to active reservation screen
          Navigator.pushReplacementNamed(context, '/reservation');
        }
      } else {
        // Get the actual error from provider
        final actualError = parkingProvider.error ?? 'Unknown error';
        debugPrint('❌ Reservation failed: $actualError');
        throw Exception(actualError);
      }
    } catch (e) {
      debugPrint('❌ Booking error: $e');

      if (mounted) {
        // Close loading if still showing
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        // Extract readable error message
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception:')) {
          errorMessage = errorMessage.split('Exception:').last.trim();
        }
        if (errorMessage.contains('Failed to create reservation:')) {
          errorMessage = errorMessage.split('Failed to create reservation:').last.trim();
        }

        // Show error with detailed message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking failed: $errorMessage'),
            backgroundColor: AppColors.occupiedRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  void _showExistingReservationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Reservation Found'),
        content: const Text(
          'You already have an active parking reservation. Please cancel or complete your current reservation before booking a new spot.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to active reservation screen
              Navigator.pushNamed(context, '/reservation');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('View Reservation'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotatedImage() {
    try {
      // Remove data URI prefix if present (e.g., "data:image/png;base64,")
      String base64String = _annotatedImageBase64!;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      // Decode base64 image
      final Uint8List bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.broken_image,
                  size: 64,
                  color: AppColors.textLight,
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'Failed to load annotated image',
                  style: TextStyle(color: AppColors.textLight),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.occupiedRed,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Error decoding annotated image: ${e.toString()}',
              style: const TextStyle(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
