import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../providers/parking_provider.dart';
import '../../models/parking_zone_model.dart';

class CampusSelectionScreen extends StatefulWidget {
  const CampusSelectionScreen({Key? key}) : super(key: key);

  @override
  State<CampusSelectionScreen> createState() => _CampusSelectionScreenState();
}

class _CampusSelectionScreenState extends State<CampusSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Load zones if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
      if (parkingProvider.zones.isEmpty) {
        parkingProvider.listenToZones();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Campus'),
      ),
      body: Consumer<ParkingProvider>(
        builder: (context, parkingProvider, _) {
          // Show loading indicator
          if (parkingProvider.isLoading && parkingProvider.zones.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: AppSizes.md),
                  Text('Loading parking zones...'),
                ],
              ),
            );
          }

          // Show error if zones failed to load
          if (!parkingProvider.isLoading && parkingProvider.zones.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.occupiedRed.withOpacity(0.5),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'No zones available',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    const Text(
                      'Please create Firestore indexes\nand try again',
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    ElevatedButton(
                      onPressed: () {
                        parkingProvider.listenToZones();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group zones by campus type
          final femaleZones = parkingProvider.zones
              .where((zone) => zone.campus == CampusType.female)
              .toList();
          final maleZones = parkingProvider.zones
              .where((zone) => zone.campus == CampusType.male)
              .toList();
          final visitorZones = parkingProvider.zones
              .where((zone) => zone.campus == CampusType.visitor)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select your parking area',
                  style: AppTextStyles.bodyLight,
                ),
                const SizedBox(height: AppSizes.xl),
                // Female Campus
                if (femaleZones.isNotEmpty)
                  _CampusCard(
                    title: 'FEMALE CAMPUS',
                    icon: Icons.female,
                    zones: femaleZones.map((zone) => {
                      'name': zone.zoneName,
                      'spots': zone.availableSpots,
                    }).toList(),
                    totalAvailable: femaleZones.fold<int>(
                      0, (sum, zone) => sum + zone.availableSpots),
                    onSelect: () {
                      Navigator.pushNamed(context, '/parking-gallery');
                    },
                  ),
                const SizedBox(height: AppSizes.lg),
                // Male Campus
                if (maleZones.isNotEmpty)
                  _CampusCard(
                    title: 'MALE CAMPUS',
                    icon: Icons.male,
                    zones: maleZones.map((zone) => {
                      'name': zone.zoneName,
                      'spots': zone.availableSpots,
                    }).toList(),
                    totalAvailable: maleZones.fold<int>(
                      0, (sum, zone) => sum + zone.availableSpots),
                    onSelect: () {
                      Navigator.pushNamed(context, '/parking-gallery');
                    },
                  ),
                const SizedBox(height: AppSizes.lg),
                // Visitor Parking
                if (visitorZones.isNotEmpty)
                  _CampusCard(
                    title: 'VISITOR PARKING',
                    icon: Icons.person_outline,
                    zones: visitorZones.map((zone) => {
                      'name': zone.zoneName,
                      'spots': zone.availableSpots,
                    }).toList(),
                    totalAvailable: visitorZones.fold<int>(
                      0, (sum, zone) => sum + zone.availableSpots),
                    onSelect: () {
                      Navigator.pushNamed(context, '/parking-gallery');
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CampusCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> zones;
  final int totalAvailable;
  final VoidCallback onSelect;

  const _CampusCard({
    required this.title,
    required this.icon,
    required this.zones,
    required this.totalAvailable,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 32, color: AppColors.primaryBlue),
              const SizedBox(width: AppSizes.sm),
              Text(title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Available Zones:',
            style: AppTextStyles.captionBold,
          ),
          const SizedBox(height: AppSizes.sm),
          ...zones.map((zone) {
            final spots = zone['spots'] as int;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: spots > 0 ? AppColors.availableGreen : AppColors.occupiedRed,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    '${zone['name']}: $spots spots',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: AppSizes.md),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Text(
                  'Total:',
                  style: AppTextStyles.captionBold,
                ),
                const Spacer(),
                Text(
                  '$totalAvailable available',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.availableGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: totalAvailable > 0 ? onSelect : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
              ),
              child: const Text('SELECT'),
            ),
          ),
        ],
      ),
    );
  }
}
