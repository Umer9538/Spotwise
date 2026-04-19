import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      notificationProvider.listenToNotifications(userId);
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.reservationConfirmed:
        return Icons.check_circle;
      case NotificationType.reservationExpiring:
        return Icons.access_alarm;
      case NotificationType.reservationExpired:
        return Icons.timer_off;
      case NotificationType.reservationCancelled:
        return Icons.cancel;
      case NotificationType.spotAvailable:
        return Icons.local_parking;
      case NotificationType.weeklySummary:
        return Icons.bar_chart;
      case NotificationType.systemUpdate:
        return Icons.system_update;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.reservationConfirmed:
        return AppColors.availableGreen;
      case NotificationType.reservationExpiring:
        return AppColors.reservedYellow;
      case NotificationType.reservationExpired:
        return AppColors.occupiedRed;
      case NotificationType.reservationCancelled:
        return AppColors.occupiedRed;
      case NotificationType.spotAvailable:
        return AppColors.availableGreen;
      case NotificationType.weeklySummary:
        return AppColors.primaryBlue;
      case NotificationType.systemUpdate:
        return AppColors.primaryBlue;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer2<NotificationProvider, AuthProvider>(
            builder: (context, provider, authProvider, _) {
              final userId = authProvider.user?.uid;
              if (provider.unreadCount > 0 && userId != null) {
                return TextButton(
                  onPressed: () => provider.markAllAsRead(userId),
                  child: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: AppSizes.sm),
                _buildFilterChip('Reservations'),
                const SizedBox(width: AppSizes.sm),
                _buildFilterChip('System'),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, _) {
                var notifications = notificationProvider.notifications;

                // Filter notifications based on selected filter
                if (_selectedFilter == 'Reservations') {
                  notifications = notifications.where((n) =>
                    n.type == NotificationType.reservationConfirmed ||
                    n.type == NotificationType.reservationExpiring ||
                    n.type == NotificationType.reservationCancelled
                  ).toList();
                } else if (_selectedFilter == 'System') {
                  notifications = notifications.where((n) =>
                    n.type == NotificationType.systemUpdate ||
                    n.type == NotificationType.weeklySummary
                  ).toList();
                }

                if (notifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: AppColors.textLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'No notifications',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'You\'re all caught up!',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length + 1,
                  itemBuilder: (context, index) {
                    if (index == notifications.length) {
                      final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
                      return Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: Center(
                          child: TextButton(
                            onPressed: userId != null
                                ? () => notificationProvider.deleteAllNotifications(userId)
                                : null,
                            child: const Text('Clear All'),
                          ),
                        ),
                      );
                    }

                    final notification = notifications[index];
                    return _NotificationItem(
                      icon: _getNotificationIcon(notification.type),
                      iconColor: _getNotificationColor(notification.type),
                      title: notification.title,
                      message: notification.message,
                      time: _formatTime(notification.createdAt),
                      isRead: notification.isRead,
                      onTap: () {
                        if (!notification.isRead) {
                          notificationProvider.markAsRead(notification.notificationId);
                        }
                      },
                      onDismiss: () {
                        notificationProvider.deleteNotification(notification.notificationId);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.backgroundWhite : AppColors.textDark,
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(title + time),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: AppColors.occupiedRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.lg),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        color: isRead ? null : AppColors.primaryBlue.withOpacity(0.05),
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            title,
            style: AppTextStyles.body.copyWith(
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.xs),
              Text(message, style: AppTextStyles.caption),
              const SizedBox(height: AppSizes.xs),
              Text(
                time,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          trailing: !isRead
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
        ),
      ),
    );
  }
}
