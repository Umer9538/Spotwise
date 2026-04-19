import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/parking_history_model.dart';

class ParkingHistoryScreen extends StatefulWidget {
  const ParkingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ParkingHistoryScreen> createState() => _ParkingHistoryScreenState();
}

class _ParkingHistoryScreenState extends State<ParkingHistoryScreen> {
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      setState(() => _isLoading = true);

      DateTime startDate;
      final now = DateTime.now();

      if (_selectedFilter == 'This Week') {
        startDate = now.subtract(const Duration(days: 7));
      } else if (_selectedFilter == 'This Month') {
        startDate = DateTime(now.year, now.month - 1, now.day);
      } else {
        // All - load from beginning of time
        startDate = DateTime(2020, 1, 1);
      }

      await parkingProvider.loadHistoryByPeriod(
        userId: userId,
        startDate: startDate,
        endDate: now,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking History'),
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
                _buildFilterChip('This Week'),
                const SizedBox(width: AppSizes.sm),
                _buildFilterChip('This Month'),
              ],
            ),
          ),
          // History List
          Expanded(
            child: Consumer<ParkingProvider>(
              builder: (context, parkingProvider, _) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final history = parkingProvider.parkingHistory;

                if (history.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: AppColors.textLight.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        Text(
                          'No Parking History',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'Your completed parking sessions will appear here',
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
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSizes.md),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return _HistoryCard(entry: item);
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
        _loadHistory();
      },
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.backgroundWhite : AppColors.textDark,
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ParkingHistoryModel entry;

  const _HistoryCard({
    required this.entry,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    String dateStr;
    if (entryDate == today) {
      dateStr = 'Today';
    } else if (entryDate == yesterday) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${date.day}/${date.month}/${date.year}';
    }

    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$dateStr, $hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getStatusColor(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.completed:
        return AppColors.availableGreen;
      case HistoryStatus.cancelled:
        return AppColors.reservedYellow;
      case HistoryStatus.expired:
        return AppColors.occupiedRed;
    }
  }

  IconData _getStatusIcon(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.completed:
        return Icons.check_circle;
      case HistoryStatus.cancelled:
        return Icons.cancel;
      case HistoryStatus.expired:
        return Icons.timer_off;
    }
  }

  String _getStatusText(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.completed:
        return 'Completed';
      case HistoryStatus.cancelled:
        return 'Cancelled';
      case HistoryStatus.expired:
        return 'Expired';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    border: Border.all(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Image.asset(
                    'assets/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.local_parking,
                        color: AppColors.primaryBlue,
                        size: 24,
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.zoneName}, Spot ${entry.spotNumber}',
                        style: AppTextStyles.body,
                      ),
                      Text(
                        _formatDate(entry.startTime),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(entry.status),
                      size: 16,
                      color: _getStatusColor(entry.status),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      _getStatusText(entry.status),
                      style: AppTextStyles.caption.copyWith(
                        color: _getStatusColor(entry.status),
                      ),
                    ),
                  ],
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
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Duration: ${_formatDuration(entry.duration)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
