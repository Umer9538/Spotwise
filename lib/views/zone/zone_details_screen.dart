import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../models/parking_zone_model.dart';
import '../../providers/parking_provider.dart';

class ZoneDetailsScreen extends StatefulWidget {
  const ZoneDetailsScreen({Key? key}) : super(key: key);

  @override
  State<ZoneDetailsScreen> createState() => _ZoneDetailsScreenState();
}

class _ZoneDetailsScreenState extends State<ZoneDetailsScreen> {
  ParkingZoneModel? _zone;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get zone from navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is ParkingZoneModel) {
      _zone = args;
    } else if (_zone == null) {
      // Fallback: get first zone from provider
      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
      if (parkingProvider.zones.isNotEmpty) {
        _zone = parkingProvider.zones.first;
      }
    }
  }

  Future<void> _openDirections(ParkingZoneModel zone) async {
    final lat = zone.coordinates.latitude;
    final lng = zone.coordinates.longitude;

    // Try Google Maps first (most common)
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

    // Apple Maps fallback for iOS
    final appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d');

    try {
      // Try launching Google Maps URL
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(appleMapsUrl)) {
        // Fallback to Apple Maps on iOS
        await launchUrl(appleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        // If neither works, show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open maps. Please install Google Maps or Apple Maps.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening maps: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_zone == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zone Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final zone = _zone!;

    return Scaffold(
      appBar: AppBar(
        title: Text(zone.zoneName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone Image/Map
            Container(
              height: 200,
              width: double.infinity,
              color: AppColors.backgroundGray,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 80,
                          color: AppColors.textLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          '${zone.campus.name.toUpperCase()} Campus',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: AppSizes.md,
                    right: AppSizes.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            'Live',
                            style: AppTextStyles.small.copyWith(
                              color: AppColors.availableGreen,
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
            Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Building: ${zone.building}',
                    style: AppTextStyles.bodyLight,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Availability Stats
                  CustomCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.circle,
                            iconColor: AppColors.availableGreen,
                            label: 'Available',
                            value: '${zone.availableSpots}',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.disabledGray,
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.circle,
                            iconColor: AppColors.occupiedRed,
                            label: 'Occupied',
                            value: '${zone.totalSpots - zone.availableSpots}',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.disabledGray,
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.local_parking,
                            iconColor: AppColors.primaryBlue,
                            label: 'Total',
                            value: '${zone.totalSpots}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Occupancy Bar
                  Builder(
                    builder: (context) {
                      // Calculate occupancy rate
                      final occupancyRate = zone.totalSpots > 0
                          ? (zone.occupiedSpots / zone.totalSpots * 100)
                          : 0.0;

                      return Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: occupancyRate / 100,
                              backgroundColor: AppColors.availableGreen.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                occupancyRate > 80
                                    ? AppColors.occupiedRed
                                    : occupancyRate > 60
                                        ? AppColors.reservedYellow
                                        : AppColors.availableGreen,
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Text(
                            '${occupancyRate.toStringAsFixed(0)}%',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Location Details
                  Text(
                    'Location Details',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _DetailItem(
                    icon: Icons.location_on,
                    text: '${zone.campus.name.toUpperCase()} Campus - ${zone.building}',
                  ),
                  _DetailItem(
                    icon: Icons.access_time,
                    text: 'Hours: Open 24/7',
                  ),
                  _DetailItem(
                    icon: Icons.check_circle,
                    text: 'Currently Open',
                    iconColor: AppColors.availableGreen,
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Features
                  Text(
                    'Features',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _FeatureItem(text: '${zone.campus.name.toUpperCase()} Campus parking'),
                  _FeatureItem(text: 'CCTV monitored'),
                  _FeatureItem(text: 'Well-lit area'),
                  ...zone.features.map((feature) => _FeatureItem(text: feature)),
                  const SizedBox(height: AppSizes.xl),
                  // Action Buttons
                  if (zone.availableSpots > 0)
                    CustomButton(
                      text: 'View Available Spots (${zone.availableSpots})',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/spot-selection',
                          arguments: zone,
                        );
                      },
                    )
                  else
                    CustomButton(
                      text: 'No Spots Available',
                      onPressed: () {},
                    ),
                  const SizedBox(height: AppSizes.md),
                  CustomButton(
                    text: 'Get Directions',
                    onPressed: () => _openDirections(zone),
                    isOutlined: true,
                    icon: Icons.directions,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  // Activity
                  Text(
                    'Zone Information',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Zone ID: ${zone.zoneId}',
                          style: AppTextStyles.caption.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Last updated: Just now',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Status: Active',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.availableGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(height: AppSizes.xs),
        Text(value, style: AppTextStyles.h3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;

  const _DetailItem({
    required this.icon,
    required this.text,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor ?? AppColors.primaryBlue),
          const SizedBox(width: AppSizes.md),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: AppColors.availableGreen,
          ),
          const SizedBox(width: AppSizes.md),
          Text(text, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
