import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  const ReservationConfirmationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.xxl),
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: AppColors.availableGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: AppColors.backgroundWhite,
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              // Title
              Text(
                'Reservation Confirmed!',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'Your spot is waiting',
                style: AppTextStyles.bodyLight,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xxl),
              // Reservation Details Card
              CustomCard(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(AppSizes.sm),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Spot A5',
                      style: AppTextStyles.h1,
                    ),
                    Text(
                      'Zone A, Building 1',
                      style: AppTextStyles.bodyLight,
                    ),
                    Text(
                      'Female Campus',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    const Divider(),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Reserved for:',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '30 minutes',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Expires in:',
                      style: AppTextStyles.caption,
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Text(
                        '29:45',
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 48,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    const Divider(),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Confirmation Code:',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      '#SP2458',
                      style: AppTextStyles.h2.copyWith(
                        fontFamily: 'Courier',
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              // Action Buttons
              CustomButton(
                text: 'Get Directions',
                onPressed: () {
                  Navigator.pushNamed(context, '/navigation');
                },
                icon: Icons.navigation,
              ),
              const SizedBox(height: AppSizes.md),
              CustomButton(
                text: 'Cancel Reservation',
                onPressed: () {
                  _showCancelDialog(context);
                },
                backgroundColor: AppColors.occupiedRed,
                icon: Icons.cancel,
              ),
              const SizedBox(height: AppSizes.lg),
              // Add to Calendar
              Center(
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Add to Calendar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: const Text(
          'Are you sure you want to cancel this reservation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep it'),
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
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: AppColors.occupiedRed),
            ),
          ),
        ],
      ),
    );
  }
}
