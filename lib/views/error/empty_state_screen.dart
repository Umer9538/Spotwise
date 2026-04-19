import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';

class EmptyStateScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final List<Widget>? additionalActions;

  const EmptyStateScreen({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
    this.additionalActions,
  }) : super(key: key);

  // No Spots Available
  factory EmptyStateScreen.noSpots({
    required VoidCallback onNotifyMe,
    required VoidCallback onFindAlternative,
  }) {
    return EmptyStateScreen(
      title: 'No Spots Available',
      message:
          'All parking spots in Zone A are currently occupied.',
      icon: Icons.sentiment_dissatisfied,
      actionText: 'Notify Me When Spot Opens',
      onAction: onNotifyMe,
      additionalActions: [
        const SizedBox(height: AppSizes.md),
        CustomButton(
          text: 'Find Alternative Zones',
          onPressed: onFindAlternative,
          isOutlined: true,
          icon: Icons.map,
        ),
      ],
    );
  }

  // Connection Error
  factory EmptyStateScreen.connectionError({
    required VoidCallback onRetry,
  }) {
    return EmptyStateScreen(
      title: 'Connection Lost',
      message:
          'Unable to connect to SpotWise servers. Please check your internet connection.',
      icon: Icons.signal_wifi_off,
      actionText: 'Try Again',
      onAction: onRetry,
      additionalActions: [
        const SizedBox(height: AppSizes.md),
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            children: [
              Text(
                'Using cached data from:',
                style: AppTextStyles.caption,
              ),
              Text(
                '2 minutes ago',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Camera Offline
  factory EmptyStateScreen.cameraOffline({
    required VoidCallback onRefresh,
    required VoidCallback onChooseAnother,
  }) {
    return EmptyStateScreen(
      title: 'Camera Temporarily Unavailable',
      message:
          'Real-time updates for Zone A are currently unavailable.',
      icon: Icons.videocam_off,
      actionText: 'Refresh',
      onAction: onRefresh,
      additionalActions: [
        const SizedBox(height: AppSizes.md),
        Container(
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: AppColors.backgroundGray,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Column(
            children: [
              Text(
                'Last known status:',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.circle,
                    size: 12,
                    color: AppColors.availableGreen,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '12 spots available',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '(15 minutes ago)',
                style: AppTextStyles.small,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.reservedYellow.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning,
                size: 16,
                color: AppColors.reservedYellow,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  'This information may not be current',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.md),
        CustomButton(
          text: 'Choose Another Zone',
          onPressed: onChooseAnother,
          isOutlined: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpotWise'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.textLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: AppSizes.xl),
              Text(
                title,
                style: AppTextStyles.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                message,
                style: AppTextStyles.bodyLight,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.xxl),
              if (actionText != null && onAction != null)
                CustomButton(
                  text: actionText!,
                  onPressed: onAction!,
                ),
              if (additionalActions != null) ...additionalActions!,
            ],
          ),
        ),
      ),
    );
  }
}
