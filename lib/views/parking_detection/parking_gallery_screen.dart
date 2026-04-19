import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../models/parking_image_model.dart';
import '../../models/parking_zone_model.dart';
import '../../services/parking_detection_service.dart';

class ParkingGalleryScreen extends StatefulWidget {
  const ParkingGalleryScreen({Key? key}) : super(key: key);

  @override
  State<ParkingGalleryScreen> createState() => _ParkingGalleryScreenState();
}

class _ParkingGalleryScreenState extends State<ParkingGalleryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ParkingImageModel> _parkingImages = [];
  Map<String, ParkingZoneModel> _zonesMap = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadParkingImages();
  }

  Future<void> _loadParkingImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load parking zones first
      final zonesSnapshot = await _firestore.collection('parking_zones').get();
      _zonesMap = {
        for (var doc in zonesSnapshot.docs)
          doc.id: ParkingZoneModel.fromJson(doc.data())
      };

      // Load parking images
      final imagesSnapshot = await _firestore
          .collection('parking_images')
          .orderBy('parkingLotName')
          .get();

      _parkingImages = imagesSnapshot.docs
          .map((doc) => ParkingImageModel.fromFirestore(doc))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Cameras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadParkingImages,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.occupiedRed,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'Error loading parking cameras',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              _error!,
              style: AppTextStyles.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.lg),
            ElevatedButton(
              onPressed: _loadParkingImages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_parkingImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No parking cameras available',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Check back later for updates',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadParkingImages,
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSizes.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppSizes.md,
          mainAxisSpacing: AppSizes.md,
        ),
        itemCount: _parkingImages.length,
        itemBuilder: (context, index) {
          return _buildParkingImageCard(_parkingImages[index]);
        },
      ),
    );
  }

  Widget _buildParkingImageCard(ParkingImageModel parkingImage) {
    final zone = _zonesMap[parkingImage.zoneId];
    final hasCache = parkingImage.hasValidCache;
    final cacheResults = parkingImage.cachedResults;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/parking-detection',
          arguments: parkingImage,
        );
      },
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSizes.radiusMd),
                    ),
                    child: Image.network(
                      ParkingDetectionService.convertImageUrl(parkingImage.imageUrl),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.backgroundGray,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.backgroundGray,
                          child: const Icon(
                            Icons.broken_image,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                        );
                      },
                    ),
                  ),
                  // Cache indicator
                  if (hasCache)
                    Positioned(
                      top: AppSizes.xs,
                      right: AppSizes.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.availableGreen,
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cached,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            parkingImage.parkingLotName,
                            style: AppTextStyles.captionBold,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (zone != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              zone.building,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.textLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    // Cached results
                    if (hasCache && cacheResults != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xs,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: cacheResults.availableSpots > 0
                              ? AppColors.availableGreen.withOpacity(0.1)
                              : AppColors.occupiedRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_parking,
                              size: 12,
                              color: cacheResults.availableSpots > 0
                                  ? AppColors.availableGreen
                                  : AppColors.occupiedRed,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cacheResults.availableSpots}/${cacheResults.totalSpots}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cacheResults.availableSpots > 0
                                    ? AppColors.availableGreen
                                    : AppColors.occupiedRed,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.xs,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.visibility,
                              size: 12,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to detect',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
