import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/parking_zone_model.dart';

class ActiveReservationScreen extends StatefulWidget {
  const ActiveReservationScreen({Key? key}) : super(key: key);

  @override
  State<ActiveReservationScreen> createState() => _ActiveReservationScreenState();
}

class _ActiveReservationScreenState extends State<ActiveReservationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadReservation();
    _startTimer();
  }

  Future<void> _loadReservation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      parkingProvider.listenToActiveReservation(userId);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Force UI rebuild every second to update time remaining
        });
      }
    });
  }

  Future<void> _extendReservation(int additionalMinutes) async {
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final reservation = parkingProvider.activeReservation;

    if (reservation == null) return;

    try {
      final success = await parkingProvider.extendReservation(
        reservationId: reservation.reservationId,
        additionalDuration: Duration(minutes: additionalMinutes),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reservation extended by $additionalMinutes minutes'),
              backgroundColor: AppColors.availableGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to extend reservation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation() async {
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final reservation = parkingProvider.activeReservation;

    if (reservation == null) return;

    try {
      final success = await parkingProvider.cancelReservation(
        reservation.reservationId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation cancelled'),
              backgroundColor: AppColors.availableGreen,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel reservation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Reservation'),
      ),
      body: Consumer<ParkingProvider>(
        builder: (context, parkingProvider, _) {
          final reservation = parkingProvider.activeReservation;

          if (reservation == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: AppColors.textLight.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    'No Active Reservation',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    'Book a parking spot to see your reservation here',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xl),
                  CustomButton(
                    text: 'FIND PARKING',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            );
          }

          // Calculate time remaining
          final now = DateTime.now();
          final timeRemaining = reservation.expiresAt.difference(now);
          final secondsRemaining = timeRemaining.inSeconds.clamp(0, double.infinity).toInt();

          final minutes = secondsRemaining ~/ 60;
          final seconds = secondsRemaining % 60;
          final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

          final isExpiringSoon = secondsRemaining <= 300; // 5 minutes

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              children: [
                // Timer
                Container(
                  padding: const EdgeInsets.all(AppSizes.xxl),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Text(
                        timeString,
                        style: AppTextStyles.h1.copyWith(
                          fontSize: 64,
                          color: AppColors.backgroundWhite,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        'Time Remaining',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.backgroundWhite,
                        ),
                      ),
                      if (isExpiringSoon) ...[
                        const SizedBox(height: AppSizes.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.reservedYellow,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning,
                                size: 16,
                                color: AppColors.backgroundWhite,
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Text(
                                'Reservation expiring soon!',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.backgroundWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.xl),
                // Spot Details
                Text(
                  'Spot Details',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: AppSizes.md),
                CustomCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.local_parking,
                        label: 'Spot',
                        value: reservation.spotNumber,
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.location_on,
                        label: 'Zone',
                        value: parkingProvider.zones
                            .firstWhere(
                              (z) => z.zoneId == reservation.zoneId,
                              orElse: () => parkingProvider.zones.isNotEmpty
                                  ? parkingProvider.zones.first
                                  : ParkingZoneModel(
                                      zoneId: '',
                                      zoneName: 'Unknown',
                                      cameraId: '',
                                      totalSpots: 0,
                                      availableSpots: 0,
                                      occupiedSpots: 0,
                                      reservedSpots: 0,
                                      campus: CampusType.male,
                                      building: '',
                                      coordinates: Coordinates(latitude: 0, longitude: 0),
                                      features: [],
                                      lastUpdated: DateTime.now(),
                                    ),
                            )
                            .zoneName,
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.access_time,
                        label: 'Duration',
                        value: '${reservation.duration.inMinutes} min',
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.schedule,
                        label: 'Start Time',
                        value: _formatTime(reservation.reservedAt),
                      ),
                      const Divider(),
                      _DetailRow(
                        icon: Icons.confirmation_number,
                        label: 'Reservation ID',
                        value: '#${reservation.reservationId.substring(0, 8).toUpperCase()}',
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
                      child: CustomButton(
                        text: 'Extend Time',
                        onPressed: () {
                          _showExtendDialog();
                        },
                        isOutlined: true,
                        icon: Icons.access_time,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel Booking',
                        onPressed: () {
                          _showCancelDialog();
                        },
                        backgroundColor: AppColors.occupiedRed,
                        icon: Icons.cancel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),
                // Important Info
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Text(
                            'Important',
                            style: AppTextStyles.captionBold,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      _InfoItem(
                        text: 'Please arrive within reservation time',
                      ),
                      _InfoItem(
                        text: 'Spot auto-releases if not claimed in 10 min',
                      ),
                      _InfoItem(
                        text: "You'll receive alerts at 5 min before expiry",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                // Help Link
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Need Help? ',
                      style: AppTextStyles.body,
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Support contact feature coming soon!'),
                          ),
                        );
                      },
                      child: Text(
                        'Contact Support',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showExtendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How much time would you like to add?'),
            const SizedBox(height: AppSizes.md),
            ListTile(
              title: const Text('15 minutes'),
              onTap: () {
                Navigator.pop(context);
                _extendReservation(15);
              },
            ),
            ListTile(
              title: const Text('30 minutes'),
              onTap: () {
                Navigator.pop(context);
                _extendReservation(30);
              },
            ),
            ListTile(
              title: const Text('60 minutes'),
              onTap: () {
                Navigator.pop(context);
                _extendReservation(60);
              },
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

  void _showCancelDialog() {
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
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelReservation();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: AppSizes.md),
          Text(label, style: AppTextStyles.caption),
          const Spacer(),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String text;

  const _InfoItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: AppTextStyles.caption),
          Expanded(
            child: Text(text, style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}
