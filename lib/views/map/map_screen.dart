import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_card.dart';
import '../../providers/parking_provider.dart';
import '../../models/parking_zone_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
    parkingProvider.listenToZones();
  }

  List<ParkingZoneModel> _getFilteredZones(List<ParkingZoneModel> zones) {
    var filtered = zones;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((zone) =>
        zone.zoneName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        zone.building.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Apply availability filter
    if (_selectedFilter == 'Available') {
      filtered = filtered.where((zone) => zone.availableSpots > 0).toList();
    } else if (_selectedFilter == 'Female') {
      filtered = filtered.where((zone) => zone.campus == CampusType.female).toList();
    } else if (_selectedFilter == 'Male') {
      filtered = filtered.where((zone) => zone.campus == CampusType.male).toList();
    }

    // Sort by available spots (descending)
    filtered.sort((a, b) => b.availableSpots.compareTo(a.availableSpots));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Zones'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadZones,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search parking zones...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Campus Overview Stats
              Consumer<ParkingProvider>(
                builder: (context, parkingProvider, _) {
                  final zones = parkingProvider.zones;
                  final totalSpots = zones.fold<int>(0, (sum, z) => sum + z.totalSpots);
                  final availableSpots = zones.fold<int>(0, (sum, z) => sum + z.availableSpots);
                  final occupancyRate = totalSpots > 0
                      ? ((totalSpots - availableSpots) / totalSpots * 100).round()
                      : 0;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      gradient: AppColors.blueGradient,
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.school, color: Colors.white, size: 28),
                            const SizedBox(width: AppSizes.md),
                            Text(
                              'PSU Campus Parking',
                              style: AppTextStyles.h3.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatColumn(
                              value: '$availableSpots',
                              label: 'Available',
                              icon: Icons.check_circle,
                              color: AppColors.availableGreen,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _StatColumn(
                              value: '$totalSpots',
                              label: 'Total Spots',
                              icon: Icons.local_parking,
                              color: Colors.white,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _StatColumn(
                              value: '$occupancyRate%',
                              label: 'Occupancy',
                              icon: Icons.pie_chart,
                              color: occupancyRate > 80
                                  ? AppColors.occupiedRed
                                  : AppColors.reservedYellow,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSizes.lg),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      const SizedBox(width: AppSizes.sm),
                      _buildFilterChip('Available'),
                      const SizedBox(width: AppSizes.sm),
                      _buildFilterChip('Female'),
                      const SizedBox(width: AppSizes.sm),
                      _buildFilterChip('Male'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.lg),

              // Parking Zones
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                child: Consumer<ParkingProvider>(
                  builder: (context, parkingProvider, _) {
                    if (parkingProvider.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.xxl),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final zones = _getFilteredZones(parkingProvider.zones);

                    if (zones.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.xxl),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.textLight.withOpacity(0.5),
                              ),
                              const SizedBox(height: AppSizes.md),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No zones match your search'
                                    : 'No parking zones available',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parking Zones (${zones.length})',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Grid of zone cards
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: AppSizes.md,
                            mainAxisSpacing: AppSizes.md,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: zones.length,
                          itemBuilder: (context, index) {
                            return _ZoneGridCard(
                              zone: zones[index],
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/zone-details',
                                  arguments: zones[index],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSizes.xxl),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/parking-gallery');
        },
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.videocam_rounded),
        label: const Text('View Cameras'),
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

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: AppSizes.xs),
        Text(
          value,
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class _ZoneGridCard extends StatelessWidget {
  final ParkingZoneModel zone;
  final VoidCallback onTap;

  const _ZoneGridCard({
    required this.zone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate occupancy rate
    final occupancyRate = zone.totalSpots > 0
        ? (zone.occupiedSpots / zone.totalSpots * 100)
        : 0.0;

    Color statusColor;
    String statusText;

    if (zone.availableSpots == 0) {
      statusColor = AppColors.occupiedRed;
      statusText = 'Full';
    } else if (occupancyRate > 80) {
      statusColor = AppColors.reservedYellow;
      statusText = 'Limited';
    } else {
      statusColor = AppColors.availableGreen;
      statusText = 'Available';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with zone icon
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusLg),
                  topRight: Radius.circular(AppSizes.radiusLg),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.local_parking,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Zone info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone.zoneName,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${zone.campus.name.toUpperCase()} Campus',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${zone.availableSpots}',
                              style: AppTextStyles.h3.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              ' / ${zone.totalSpots}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: zone.availableSpots / zone.totalSpots,
                          backgroundColor: AppColors.backgroundGray,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
