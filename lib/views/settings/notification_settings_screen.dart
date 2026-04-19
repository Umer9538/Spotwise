import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushEnabled = true;
  bool _reservationConfirmed = true;
  bool _expiryWarning = true;
  bool _reservationExpired = true;
  bool _spotsAvailable = false;
  bool _favoriteZoneOpen = false;
  bool _emailWeeklySummary = true;
  bool _emailSystemUpdates = true;
  bool _dndEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        children: [
          // Push Notifications
          _SectionHeader(title: 'Push Notifications'),
          _SwitchTile(
            title: 'Enable Notifications',
            value: _pushEnabled,
            onChanged: (value) {
              setState(() {
                _pushEnabled = value;
              });
            },
          ),
          const SizedBox(height: AppSizes.md),
          // Reservation Alerts
          _SectionHeader(title: 'Reservation Alerts'),
          _SwitchTile(
            title: 'Reservation confirmed',
            value: _reservationConfirmed,
            onChanged: _pushEnabled
                ? (value) {
                    setState(() {
                      _reservationConfirmed = value;
                    });
                  }
                : null,
          ),
          _SwitchTile(
            title: '5-min expiry warning',
            value: _expiryWarning,
            onChanged: _pushEnabled
                ? (value) {
                    setState(() {
                      _expiryWarning = value;
                    });
                  }
                : null,
          ),
          _SwitchTile(
            title: 'Reservation expired',
            value: _reservationExpired,
            onChanged: _pushEnabled
                ? (value) {
                    setState(() {
                      _reservationExpired = value;
                    });
                  }
                : null,
          ),
          const SizedBox(height: AppSizes.md),
          // Availability Alerts
          _SectionHeader(title: 'Availability Alerts'),
          _SwitchTile(
            title: 'Spots available',
            value: _spotsAvailable,
            onChanged: _pushEnabled
                ? (value) {
                    setState(() {
                      _spotsAvailable = value;
                    });
                  }
                : null,
          ),
          _SwitchTile(
            title: 'Favorite zone open',
            value: _favoriteZoneOpen,
            onChanged: _pushEnabled
                ? (value) {
                    setState(() {
                      _favoriteZoneOpen = value;
                    });
                  }
                : null,
          ),
          const SizedBox(height: AppSizes.md),
          // Email Notifications
          _SectionHeader(title: 'Email Notifications'),
          _SwitchTile(
            title: 'Weekly summary',
            value: _emailWeeklySummary,
            onChanged: (value) {
              setState(() {
                _emailWeeklySummary = value;
              });
            },
          ),
          _SwitchTile(
            title: 'System updates',
            value: _emailSystemUpdates,
            onChanged: (value) {
              setState(() {
                _emailSystemUpdates = value;
              });
            },
          ),
          const SizedBox(height: AppSizes.md),
          // Do Not Disturb
          _SectionHeader(title: 'Do Not Disturb'),
          _SwitchTile(
            title: 'Enable DND',
            value: _dndEnabled,
            onChanged: (value) {
              setState(() {
                _dndEnabled = value;
              });
            },
          ),
          if (_dndEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('From: 10:00 PM'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text('To: 7:00 AM'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () {},
                  ),
                ],
              ),
            ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(
        AppSizes.lg,
        AppSizes.md,
        AppSizes.lg,
        AppSizes.sm,
      ),
      child: Text(
        title,
        style: AppTextStyles.h3,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title, style: AppTextStyles.body),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryBlue,
    );
  }
}
