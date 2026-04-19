import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Placeholder
          Container(
            color: AppColors.backgroundGray,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 100,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Navigation Map',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Top Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.backgroundWhite,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.backgroundWhite,
                    child: IconButton(
                      icon: const Icon(Icons.volume_up, color: AppColors.textDark),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Direction Card
          Positioned(
            top: 100,
            left: AppSizes.md,
            right: AppSizes.md,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_upward,
                        size: 48,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Continue Straight',
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    '50 meters',
                    style: AppTextStyles.bodyLight,
                  ),
                ],
              ),
            ),
          ),
          // Bottom Info Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLg),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.occupiedRed,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'Destination',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      'Zone A, Spot A5',
                      style: AppTextStyles.h3,
                    ),
                    Text(
                      'Building 1',
                      style: AppTextStyles.bodyLight,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Flexible(
                                child: Text(
                                  'ETA: 2 minutes',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.straighten,
                                size: 16,
                                color: AppColors.textLight,
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Flexible(
                                child: Text(
                                  'Distance: 150m',
                                  style: AppTextStyles.caption,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.reservedYellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: AppColors.reservedYellow,
                          ),
                          const SizedBox(width: AppSizes.md),
                          Text(
                            'Time Remaining: 28:15',
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    CustomButton(
                      text: "I'VE ARRIVED",
                      onPressed: () {
                        _showArrivedDialog(context);
                      },
                      backgroundColor: AppColors.availableGreen,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showArrivedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Arrived at Destination?'),
        content: const Text(
          'Have you reached your parking spot?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            child: const Text('Yes, I Arrived'),
          ),
        ],
      ),
    );
  }
}
