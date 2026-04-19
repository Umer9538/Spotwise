import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/parking_provider.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      // Load user data
      userProvider.listenToUser(userId);

      // Load parking data
      parkingProvider.listenToActiveReservation(userId);
      parkingProvider.listenToZones();
      await parkingProvider.loadRecentHistory(userId, limit: 3);

      // Load notifications
      notificationProvider.listenToNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            final user = userProvider.currentUser;
            return Text('Hello, ${user?.name ?? 'User'}!');
          },
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${notificationProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active Reservation Card
                Consumer<ParkingProvider>(
                  builder: (context, parkingProvider, _) {
                    final reservation = parkingProvider.activeReservation;
                    if (reservation != null) {
                      return _buildActiveReservationCard(reservation);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: AppSizes.lg),

                // Parking Availability
                Text('Parking Availability', style: AppTextStyles.h3),
                const SizedBox(height: AppSizes.md),
                Consumer<ParkingProvider>(
                  builder: (context, parkingProvider, _) {
                    if (parkingProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final zones = parkingProvider.zones;
                    if (zones.isEmpty) {
                      return const Text('No parking zones available');
                    }
                    return Column(
                      children: zones.take(3).map((zone) {
                        return _buildZoneCard(zone);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: AppSizes.lg),

                // Recent Activity
                Text('Recent Activity', style: AppTextStyles.h3),
                const SizedBox(height: AppSizes.md),
                Consumer<ParkingProvider>(
                  builder: (context, parkingProvider, _) {
                    final history = parkingProvider.parkingHistory;
                    if (history.isEmpty) {
                      return const Text('No recent activity');
                    }
                    return Column(
                      children: history.map((entry) {
                        return _buildHistoryCard(entry);
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(context, '/map');
              break;
            case 2:
              Navigator.pushNamed(context, '/history');
              break;
            case 3:
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildActiveReservationCard(reservation) {
    return Card(
      color: AppColors.primaryBlue,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Reservation',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
                Icon(Icons.local_parking, color: Colors.white),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Spot: ${reservation.spotNumber}',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            Text(
              'Time Remaining: ${reservation.timeRemaining.inMinutes} min',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSizes.md),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/active-reservation');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
              ),
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          icon: Icons.search,
          label: 'Find Spot',
          onTap: () => Navigator.pushNamed(context, '/campus-selection'),
        ),
        _buildQuickActionButton(
          icon: Icons.book_online,
          label: 'Book Now',
          onTap: () => Navigator.pushNamed(context, '/campus-selection'),
        ),
        _buildQuickActionButton(
          icon: Icons.bar_chart,
          label: 'Stats',
          onTap: () => Navigator.pushNamed(context, '/statistics'),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.skyBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 32),
            const SizedBox(height: AppSizes.sm),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneCard(zone) {
    final availabilityPercent = (zone.availableSpots / zone.totalSpots * 100).round();
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Icon(
          Icons.local_parking,
          color: zone.availableSpots > 0 ? AppColors.availableGreen : AppColors.occupiedRed,
        ),
        title: Text(zone.zoneName),
        subtitle: Text('${zone.availableSpots}/${zone.totalSpots} available ($availabilityPercent%)'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.pushNamed(context, '/zone-details', arguments: zone.zoneId);
        },
      ),
    );
  }

  Widget _buildHistoryCard(entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: ListTile(
        leading: Icon(Icons.history, color: AppColors.primaryBlue),
        title: Text(entry.zoneName),
        subtitle: Text('Spot ${entry.spotNumber} • ${entry.duration.inMinutes} min'),
        trailing: Text(
          _formatDate(entry.startTime),
          style: AppTextStyles.caption,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
