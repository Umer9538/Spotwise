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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Load data after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    final userId = authProvider.user?.uid;
    if (userId != null) {
      userProvider.listenToUser(userId);
      parkingProvider.listenToActiveReservation(userId);
      parkingProvider.listenToZones();
      await parkingProvider.loadRecentHistory(userId, limit: 3);
      notificationProvider.listenToNotifications(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Modern App Bar with Gradient
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                  ),
                ),
                title: Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    final user = userProvider.currentUser;
                    return Text(
                      'Hello, ${user?.name.split(' ').first ?? 'User'}! 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              actions: [
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                          onPressed: () => Navigator.pushNamed(context, '/notifications'),
                        ),
                        if (notificationProvider.unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                              child: Text(
                                '${notificationProvider.unreadCount}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

            // Content
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Dashboard
                      _buildQuickStats(),
                      const SizedBox(height: AppSizes.xl),

                      // Active Reservation Card
                      Consumer<ParkingProvider>(
                        builder: (context, parkingProvider, _) {
                          final reservation = parkingProvider.activeReservation;
                          if (reservation != null) {
                            return Column(
                              children: [
                                _buildActiveReservationCard(reservation),
                                const SizedBox(height: AppSizes.xl),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Quick Actions with Modern Design
                      _buildModernQuickActions(),
                      const SizedBox(height: AppSizes.xl),

                      // Featured Parking Zones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Available Zones', style: AppTextStyles.h3),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/map'),
                            child: const Text('See All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Consumer<ParkingProvider>(
                        builder: (context, parkingProvider, _) {
                          if (parkingProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final zones = parkingProvider.zones.where((z) => z.availableSpots > 0).toList();
                          if (zones.isEmpty) {
                            return _buildModernEmptyState(
                              icon: Icons.local_parking_outlined,
                              title: 'No Zones Available',
                              subtitle: 'Check back later for parking availability',
                            );
                          }
                          return SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: zones.length,
                              itemBuilder: (context, index) => _buildModernZoneCard(zones[index]),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Recent Activity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Activity', style: AppTextStyles.h3),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/history'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      Consumer<ParkingProvider>(
                        builder: (context, parkingProvider, _) {
                          final history = parkingProvider.parkingHistory;
                          if (history.isEmpty) {
                            return _buildModernEmptyState(
                              icon: Icons.history,
                              title: 'No Activity Yet',
                              subtitle: 'Your parking history will appear here',
                            );
                          }
                          return Column(
                            children: history.map((entry) => _buildModernHistoryCard(entry)).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: AppSizes.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            switch (index) {
              case 0: break;
              case 1: Navigator.pushNamed(context, '/map'); break;
              case 2: Navigator.pushNamed(context, '/history'); break;
              case 3: Navigator.pushNamed(context, '/profile'); break;
            }
          },
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.textLight,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<ParkingProvider>(
      builder: (context, parkingProvider, _) {
        final totalZones = parkingProvider.zones.length;
        final availableZones = parkingProvider.zones.where((z) => z.availableSpots > 0).length;
        final totalAvailableSpots = parkingProvider.zones.fold<int>(0, (sum, zone) => sum + zone.availableSpots);
        final hasActiveReservation = parkingProvider.activeReservation != null;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Total Zones', '$totalZones', Icons.location_city, Colors.blue)),
            const SizedBox(width: AppSizes.sm),
            Expanded(child: _buildStatCard('Available', '$availableZones', Icons.check_circle, Colors.green)),
            const SizedBox(width: AppSizes.sm),
            Expanded(child: _buildStatCard('Spots', '$totalAvailableSpots', Icons.local_parking, Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(value, style: AppTextStyles.h2.copyWith(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textLight), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildActiveReservationCard(reservation) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🚗 Active Reservation', style: AppTextStyles.h3.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Spot ${reservation.spotNumber}', style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.local_parking, color: Colors.white, size: 32),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${reservation.timeRemaining.inMinutes} min remaining', style: AppTextStyles.body.copyWith(color: Colors.white)),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/reservation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: AppSizes.md,
      crossAxisSpacing: AppSizes.md,
      children: [
        _buildModernActionCard(
          icon: Icons.videocam_rounded,
          label: 'Find Spot',
          gradient: const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
          onTap: () => Navigator.pushNamed(context, '/parking-gallery'),
        ),
        _buildModernActionCard(
          icon: Icons.bookmark_rounded,
          label: 'Book Now',
          gradient: const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
          onTap: () => Navigator.pushNamed(context, '/campus-selection'),
        ),
        _buildModernActionCard(
          icon: Icons.bar_chart_rounded,
          label: 'Stats',
          gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
          onTap: () => Navigator.pushNamed(context, '/statistics'),
        ),
      ],
    );
  }

  Widget _buildModernActionCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: AppSizes.sm),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernZoneCard(zone) {
    final availabilityPercent = (zone.availableSpots / zone.totalSpots * 100).round();
    final Color statusColor = zone.availableSpots > zone.totalSpots * 0.5
        ? AppColors.availableGreen
        : zone.availableSpots > 0
            ? AppColors.reservedYellow
            : AppColors.occupiedRed;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/zone-details', arguments: zone),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.local_parking, color: statusColor, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$availabilityPercent%',
                        style: AppTextStyles.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  zone.zoneName,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${zone.availableSpots}/${zone.totalSpots} available',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: AppSizes.sm),
                LinearProgressIndicator(
                  value: zone.availableSpots / zone.totalSpots,
                  backgroundColor: AppColors.backgroundGray,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHistoryCard(entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSizes.md),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.history, color: AppColors.primaryBlue),
        ),
        title: Text(entry.zoneName, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Spot ${entry.spotNumber} • ${entry.duration.inMinutes} min', style: AppTextStyles.caption),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_formatDate(entry.startTime), style: AppTextStyles.caption.copyWith(color: AppColors.textLight)),
            const SizedBox(height: 4),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundGray, width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.textLight),
          ),
          const SizedBox(height: AppSizes.md),
          Text(title, style: AppTextStyles.h3.copyWith(color: AppColors.textDark)),
          const SizedBox(height: AppSizes.sm),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
