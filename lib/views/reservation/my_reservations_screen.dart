import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/reservation_model.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({Key? key}) : super(key: key);

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      setState(() => _isLoading = true);
      await parkingProvider.loadUserReservations(userId);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ReservationModel> _getFilteredReservations(List<ReservationModel> reservations) {
    if (_selectedFilter == 'Active') {
      return reservations.where((r) => r.status == ReservationStatus.active).toList();
    } else if (_selectedFilter == 'Completed') {
      return reservations.where((r) => r.status == ReservationStatus.completed).toList();
    } else if (_selectedFilter == 'Cancelled') {
      return reservations.where((r) => 
        r.status == ReservationStatus.cancelled || 
        r.status == ReservationStatus.expired
      ).toList();
    }
    return reservations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: AppSizes.sm),
                  _buildFilterChip('Active'),
                  const SizedBox(width: AppSizes.sm),
                  _buildFilterChip('Completed'),
                  const SizedBox(width: AppSizes.sm),
                  _buildFilterChip('Cancelled'),
                ],
              ),
            ),
          ),
          // Reservations List
          Expanded(
            child: Consumer<ParkingProvider>(
              builder: (context, parkingProvider, _) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reservations = _getFilteredReservations(parkingProvider.userReservations);

                if (reservations.isEmpty) {
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
                          'No Reservations',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          _selectedFilter == 'All'
                              ? 'You haven\'t made any reservations yet'
                              : 'No $_selectedFilter reservations found',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.md),
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      return _ReservationCard(
                        reservation: reservation,
                        onTap: () {
                          if (reservation.status == ReservationStatus.active) {
                            Navigator.pushNamed(context, '/reservation');
                          }
                        },
                      );
                    },
                  ),
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

class _ReservationCard extends StatelessWidget {
  final ReservationModel reservation;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.onTap,
  });

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.active:
        return AppColors.primaryBlue;
      case ReservationStatus.completed:
        return AppColors.availableGreen;
      case ReservationStatus.cancelled:
        return AppColors.reservedYellow;
      case ReservationStatus.expired:
        return AppColors.occupiedRed;
    }
  }

  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.active:
        return Icons.timer;
      case ReservationStatus.completed:
        return Icons.check_circle;
      case ReservationStatus.cancelled:
        return Icons.cancel;
      case ReservationStatus.expired:
        return Icons.timer_off;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (dateOnly == today) {
      dateStr = 'Today';
    } else if (dateOnly == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$dateStr, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(reservation.status);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Icon(
                      _getStatusIcon(reservation.status),
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spot ${reservation.spotNumber}',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(reservation.reservedAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reservation.status.name.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              Container(
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          '${reservation.duration.inMinutes} min',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number,
                          size: 16,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          '#${reservation.confirmationCode}',
                          style: AppTextStyles.caption.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (reservation.status == ReservationStatus.active)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.md),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          'Tap to view active reservation details',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
