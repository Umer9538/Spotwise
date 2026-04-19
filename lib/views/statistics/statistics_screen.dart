import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/parking_history_model.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Week';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      DateTime startDate;
      final now = DateTime.now();

      switch (_selectedPeriod) {
        case 'Week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'Year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = now.subtract(const Duration(days: 7));
      }

      await parkingProvider.loadHistoryByPeriod(
        userId: userId,
        startDate: startDate,
        endDate: now,
      );
    }
  }

  Map<String, dynamic> _calculateStatistics(List<ParkingHistoryModel> history) {
    if (history.isEmpty) {
      return {
        'timesParked': 0,
        'totalHours': 0.0,
        'averageDuration': 0.0,
        'favoriteZone': 'N/A',
        'zoneUsage': <Map<String, dynamic>>[],
        'peakHours': {'most': 'N/A', 'least': 'N/A'},
      };
    }

    // Times parked
    final timesParked = history.length;

    // Total hours
    final totalMinutes = history.fold<int>(
      0,
      (sum, record) => sum + record.duration.inMinutes,
    );
    final totalHours = totalMinutes / 60;

    // Average duration
    final averageDuration = totalHours / timesParked;

    // Zone usage
    final zoneUsageMap = <String, int>{};
    for (var record in history) {
      zoneUsageMap[record.zoneName] = (zoneUsageMap[record.zoneName] ?? 0) + 1;
    }

    // Sort zones by usage
    final sortedZones = zoneUsageMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate percentages
    final zoneUsage = sortedZones.take(3).map((entry) {
      final percentage = (entry.value / timesParked * 100).round();
      return {
        'name': entry.key,
        'count': entry.value,
        'percentage': percentage,
      };
    }).toList();

    // Favorite zone
    final favoriteZone = sortedZones.isNotEmpty ? sortedZones.first.key : 'N/A';

    // Peak hours analysis
    final hourUsage = <int, int>{};
    for (var record in history) {
      final hour = record.startTime.hour;
      hourUsage[hour] = (hourUsage[hour] ?? 0) + 1;
    }

    String mostFrequentHour = 'N/A';
    String leastBusyHour = 'N/A';

    if (hourUsage.isNotEmpty) {
      final sortedHours = hourUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final mostHour = sortedHours.first.key;
      final leastHour = sortedHours.last.key;

      mostFrequentHour = '${mostHour.toString().padLeft(2, '0')}:00 - ${(mostHour + 1).toString().padLeft(2, '0')}:00';
      leastBusyHour = '${leastHour.toString().padLeft(2, '0')}:00 - ${(leastHour + 1).toString().padLeft(2, '0')}:00';
    }

    return {
      'timesParked': timesParked,
      'totalHours': totalHours,
      'averageDuration': averageDuration,
      'favoriteZone': favoriteZone,
      'zoneUsage': zoneUsage,
      'peakHours': {
        'most': mostFrequentHour,
        'least': leastBusyHour,
      },
    };
  }

  String _formatDuration(double hours) {
    if (hours < 1) {
      return '${(hours * 60).toStringAsFixed(0)}m';
    } else if (hours < 10) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      return '${hours.toStringAsFixed(0)}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Stats'),
      ),
      body: Consumer<ParkingProvider>(
        builder: (context, parkingProvider, _) {
          final history = parkingProvider.parkingHistory;
          final stats = _calculateStatistics(history);

          return RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period Selector
                  Row(
                    children: [
                      _buildPeriodChip('Week'),
                      const SizedBox(width: AppSizes.sm),
                      _buildPeriodChip('Month'),
                      const SizedBox(width: AppSizes.sm),
                      _buildPeriodChip('Year'),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Loading State
                  if (parkingProvider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.xl),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else ...[
                    // Overview
                    Text(
                      'This $_selectedPeriod Overview',
                      style: AppTextStyles.h3,
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Empty State
                    if (history.isEmpty)
                      CustomCard(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.xl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.insert_chart_outlined,
                                size: 64,
                                color: AppColors.textLight.withOpacity(0.5),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                'No parking history',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: AppSizes.sm),
                              Text(
                                'Start parking to see your statistics here',
                                style: AppTextStyles.caption,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Key Metrics
                      Text(
                        'Key Metrics',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              value: '${stats['timesParked']}',
                              label: 'Times\nParked',
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: _MetricCard(
                              value: _formatDuration(stats['totalHours']),
                              label: 'Total\nHours',
                              color: AppColors.availableGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              value: _formatDuration(stats['averageDuration']),
                              label: 'Average\nDuration',
                              color: AppColors.reservedYellow,
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: _MetricCard(
                              value: stats['favoriteZone'].length > 15
                                  ? '${stats['favoriteZone'].substring(0, 12)}...'
                                  : stats['favoriteZone'],
                              label: 'Favorite\nZone',
                              color: AppColors.occupiedRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Most Used Zones
                      if ((stats['zoneUsage'] as List).isNotEmpty) ...[
                        Text(
                          'Most Used Zones',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: AppSizes.md),
                        ...(stats['zoneUsage'] as List).asMap().entries.map((entry) {
                          final index = entry.key;
                          final zone = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < (stats['zoneUsage'] as List).length - 1
                                  ? AppSizes.sm
                                  : 0,
                            ),
                            child: _ZoneUsageBar(
                              zoneName: '${index + 1}. ${zone['name']}',
                              percentage: zone['percentage'],
                              count: zone['count'],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: AppSizes.xl),
                      ],

                      // Peak Times
                      Text(
                        'Peak Parking Times',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSizes.md),
                      CustomCard(
                        child: Column(
                          children: [
                            _TimeRow(
                              label: 'Most frequent:',
                              value: stats['peakHours']['most'],
                            ),
                            const Divider(),
                            _TimeRow(
                              label: 'Least busy:',
                              value: stats['peakHours']['least'],
                            ),
                          ],
                        ),
                      ),

                      // Recent History
                      const SizedBox(height: AppSizes.xl),
                      Text(
                        'Recent Parking Sessions',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: AppSizes.md),
                      ...history.take(5).map((record) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: CustomCard(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppSizes.sm),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(record.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                ),
                                child: Icon(
                                  Icons.local_parking,
                                  color: _getStatusColor(record.status),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      record.zoneName,
                                      style: AppTextStyles.body,
                                    ),
                                    const SizedBox(height: AppSizes.xs),
                                    Text(
                                      '${_formatDate(record.startTime)} • ${_formatDuration(record.duration.inMinutes / 60)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(record.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                                ),
                                child: Text(
                                  record.status.toString().split('.').last.toUpperCase(),
                                  style: AppTextStyles.caption.copyWith(
                                    color: _getStatusColor(record.status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(HistoryStatus status) {
    switch (status) {
      case HistoryStatus.completed:
        return AppColors.availableGreen;
      case HistoryStatus.cancelled:
        return AppColors.occupiedRed;
      case HistoryStatus.expired:
        return AppColors.reservedYellow;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Widget _buildPeriodChip(String label) {
    final isSelected = _selectedPeriod == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPeriod = label;
        });
        _loadStatistics();
      },
      selectedColor: AppColors.primaryBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.backgroundWhite : AppColors.textDark,
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MetricCard({
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
              fontSize: 32,
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

class _ZoneUsageBar extends StatelessWidget {
  final String zoneName;
  final int percentage;
  final int count;

  const _ZoneUsageBar({
    required this.zoneName,
    required this.percentage,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  zoneName,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                '$percentage% ($count times)',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: AppColors.backgroundGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;

  const _TimeRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.body),
        ],
      ),
    );
  }
}
