import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Overview
            Text(
              'System Overview',
              style: AppTextStyles.h3,
            ),
            Text(
              'Last updated: 5s ago',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSizes.md),
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '156',
                    label: 'Total\nSpots',
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _StatCard(
                    value: '45',
                    label: 'Available\nSpots',
                    color: AppColors.availableGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '111',
                    label: 'Occupied',
                    color: AppColors.occupiedRed,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _StatCard(
                    value: '28',
                    label: 'Reserved',
                    color: AppColors.reservedYellow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.xl),
            // Camera Status
            Text(
              'Live Camera Status',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.md),
            _CameraCard(
              name: 'Camera 1 - Zone A',
              status: 'active',
              fps: 45,
            ),
            const SizedBox(height: AppSizes.md),
            _CameraCard(
              name: 'Camera 2 - Zone B',
              status: 'active',
              fps: 42,
            ),
            const SizedBox(height: AppSizes.md),
            _CameraCard(
              name: 'Camera 3 - Zone C',
              status: 'error',
              fps: 0,
            ),
            const SizedBox(height: AppSizes.xl),
            // Detection Performance
            Text(
              'Detection Performance',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.md),
            CustomCard(
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Accuracy:',
                    value: '94.5%',
                    color: AppColors.availableGreen,
                  ),
                  const Divider(),
                  _DetailRow(
                    label: 'Avg Processing:',
                    value: '1.2s',
                  ),
                  const Divider(),
                  _DetailRow(
                    label: 'Errors today:',
                    value: '3',
                    color: AppColors.reservedYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            // Quick Actions
            Text(
              'Quick Actions',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.smart_toy,
                    label: 'AI Detection',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(context, '/ai-detection');
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.videocam,
                    label: 'View Cameras',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.analytics,
                    label: 'Analytics',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.people,
                    label: 'Users',
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.people,
                    label: 'Users',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.h1.copyWith(
              color: color,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            label,
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CameraCard extends StatelessWidget {
  final String name;
  final String status;
  final int fps;

  const _CameraCard({
    required this.name,
    required this.status,
    required this.fps,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return CustomCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isActive
                      ? AppColors.availableGreen
                      : AppColors.occupiedRed)
                  .withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: isActive
                ? Icon(
                    Icons.videocam,
                    color: AppColors.availableGreen,
                  )
                : Icon(
                    Icons.videocam_off,
                    color: AppColors.occupiedRed,
                  ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.body),
                Text(
                  isActive ? 'Active • $fps FPS' : 'Error • Offline',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 32, color: color ?? AppColors.primaryBlue),
          const SizedBox(height: AppSizes.sm),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
