import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/user_provider.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/parking_zone_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  String _formatMemberSince(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _getCampusDisplayName(CampusType campus) {
    switch (campus) {
      case CampusType.female:
        return 'Female Campus';
      case CampusType.male:
        return 'Male Campus';
      case CampusType.visitor:
        return 'Visitor Parking';
    }
  }

  void _showCampusSelectionDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Default Campus'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CampusOption(
              campus: CampusType.female,
              label: 'Female Campus',
              icon: Icons.female,
              userId: userId,
            ),
            const SizedBox(height: AppSizes.sm),
            _CampusOption(
              campus: CampusType.male,
              label: 'Male Campus',
              icon: Icons.male,
              userId: userId,
            ),
            const SizedBox(height: AppSizes.sm),
            _CampusOption(
              campus: CampusType.visitor,
              label: 'Visitor Parking',
              icon: Icons.person_outline,
              userId: userId,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppColors.occupiedRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Consumer2<UserProvider, ParkingProvider>(
        builder: (context, userProvider, parkingProvider, _) {
          final user = userProvider.currentUser;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final totalParkings = parkingProvider.parkingHistory.length;
          final hasActive = parkingProvider.activeReservation != null ? '1' : '0';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: AppSizes.lg),
                // Profile Picture
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primaryBlue,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryBlue,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: AppColors.backgroundWhite,
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 80,
                            );

                            if (pickedFile != null) {
                              final imageFile = File(pickedFile.path);
                              final userProvider = Provider.of<UserProvider>(context, listen: false);
                              final authProvider = Provider.of<AuthProvider>(context, listen: false);
                              final userId = authProvider.user?.uid;

                              if (userId != null) {
                                // Show loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Text('Uploading photo...'),
                                      ],
                                    ),
                                    duration: Duration(seconds: 10),
                                  ),
                                );

                                final result = await userProvider.uploadProfilePicture(
                                  userId: userId,
                                  imageFile: imageFile,
                                );

                                // Hide loading snackbar
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                if (result != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile photo updated successfully!'),
                                      backgroundColor: AppColors.availableGreen,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Failed to upload photo'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  user.name,
                  style: AppTextStyles.h2,
                ),
                Text(
                  user.email,
                  style: AppTextStyles.caption,
                ),
                Text(
                  user.role.name.toUpperCase(),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSizes.lg),
                // Stats Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Member since',
                        value: _formatMemberSince(user.createdAt),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.disabledGray,
                      ),
                      _StatItem(
                        label: 'Total parkings',
                        value: '$totalParkings',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.disabledGray,
                      ),
                      _StatItem(
                        label: 'Active',
                        value: hasActive,
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: AppSizes.xl),
            // Account Section
            _SectionHeader(title: 'Account'),
            _MenuItem(
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
            ),
            _MenuItem(
              icon: Icons.confirmation_number,
              title: 'My Reservations',
              onTap: () {
                Navigator.pushNamed(context, '/my-reservations');
              },
            ),
            _MenuItem(
              icon: Icons.history,
              title: 'Parking History',
              onTap: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
            const SizedBox(height: AppSizes.md),
            // Preferences Section
            _SectionHeader(title: 'Preferences'),
            _MenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.pushNamed(context, '/notification-settings');
              },
            ),
            _MenuItem(
              icon: Icons.school,
              title: 'Default Campus',
              onTap: () => _showCampusSelectionDialog(context, user.userId),
              trailing: Text(
                user.defaultCampus != null
                    ? _getCampusDisplayName(user.defaultCampus!)
                    : 'Not set',
                style: AppTextStyles.caption,
              ),
            ),
            _MenuItem(
              icon: Icons.map,
              title: 'Map Settings',
              onTap: () {
                Navigator.pushNamed(context, '/map-settings');
              },
            ),
            const SizedBox(height: AppSizes.md),
            // Support Section
            _SectionHeader(title: 'Support'),
            _MenuItem(
              icon: Icons.help,
              title: 'Help & FAQ',
              onTap: () {
                Navigator.pushNamed(context, '/help-faq');
              },
            ),
            _MenuItem(
              icon: Icons.email,
              title: 'Contact Support',
              onTap: () {
                Navigator.pushNamed(context, '/contact-support');
              },
            ),
            _MenuItem(
              icon: Icons.privacy_tip,
              title: 'Terms & Privacy',
              onTap: () {
                Navigator.pushNamed(context, '/terms-privacy');
              },
            ),
            const SizedBox(height: AppSizes.xl),
            // Logout Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: ElevatedButton(
                onPressed: () {
                  _showLogoutDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.occupiedRed,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ),
                const SizedBox(height: AppSizes.xxl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.h3),
        const SizedBox(height: AppSizes.xs),
        Text(label, style: AppTextStyles.small),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.lg,
        vertical: AppSizes.sm,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: AppTextStyles.h3,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(icon, color: AppColors.primaryBlue),
      ),
      title: Text(title, style: AppTextStyles.body),
      trailing: trailing ??
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textLight,
          ),
      onTap: onTap,
    );
  }
}

class _CampusOption extends StatelessWidget {
  final CampusType campus;
  final String label;
  final IconData icon;
  final String userId;

  const _CampusOption({
    required this.campus,
    required this.label,
    required this.icon,
    required this.userId,
  });

  Future<void> _updateCampusPreference(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'default_campus': campus.toString().split('.').last,
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default campus updated to $label'),
            backgroundColor: AppColors.availableGreen,
          ),
        );

        // Refresh user data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUser(userId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update campus: $e'),
            backgroundColor: AppColors.occupiedRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _updateCampusPreference(context),
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue),
            const SizedBox(width: AppSizes.md),
            Text(label, style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }
}
