import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/custom_button.dart';
import '../../models/parking_zone_model.dart';
import '../../models/parking_spot_model.dart';
import '../../providers/parking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/zone_service.dart';

class SpotSelectionScreen extends StatefulWidget {
  const SpotSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SpotSelectionScreen> createState() => _SpotSelectionScreenState();
}

class _SpotSelectionScreenState extends State<SpotSelectionScreen> {
  final ZoneService _zoneService = ZoneService();

  ParkingZoneModel? _zone;
  List<ParkingSpotModel> _spots = [];
  ParkingSpotModel? _selectedSpot;
  bool _isLoading = true;
  int _selectedDuration = 30; // minutes

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get zone from navigation arguments
    if (_zone == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is ParkingZoneModel) {
        _zone = args;
        _loadSpots();
      }
    }
  }

  Future<void> _loadSpots() async {
    if (_zone == null) return;

    try {
      setState(() => _isLoading = true);

      final spots = await _zoneService.getSpotsByZone(_zone!.zoneId);

      setState(() {
        _spots = spots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading spots: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookSpot() async {
    if (_selectedSpot == null || _zone == null) return;

    try {
      final parkingProvider = Provider.of<ParkingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await parkingProvider.createReservation(
        userId: userId,
        spotId: _selectedSpot!.spotId,
        zoneId: _zone!.zoneId,
        spotNumber: _selectedSpot!.spotNumber,
        duration: Duration(minutes: _selectedDuration),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacementNamed(context, '/active-reservation');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create reservation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_zone == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select Spot')),
        body: const Center(child: Text('No zone selected')),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('${_zone!.zoneName} - Spots')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final zone = _zone!;
    final availableSpots = _spots.where((s) => s.status == SpotStatus.available).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${zone.zoneName} - Spots'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Zone Info
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            color: AppColors.backgroundGray,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${zone.campus.name.toUpperCase()} Campus',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSizes.xs),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: availableSpots > 0
                          ? AppColors.availableGreen
                          : AppColors.occupiedRed,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      '$availableSpots available',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Parking Layout
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                children: [
                  // Entrance
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'Entrance',
                          style: AppTextStyles.captionBold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  // Spots Grid
                  if (_spots.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.xl),
                        child: Text('No spots available in this zone'),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: AppSizes.md,
                        mainAxisSpacing: AppSizes.md,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: _spots.length,
                      itemBuilder: (context, index) {
                        return _buildSpotItem(_spots[index]);
                      },
                    ),
                  const SizedBox(height: AppSizes.lg),
                  // Exit
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 16),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          'Exit',
                          style: AppTextStyles.captionBold,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Legend and Filter
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(
                      color: AppColors.availableGreen,
                      label: 'Available',
                    ),
                    _LegendItem(
                      color: AppColors.occupiedRed,
                      label: 'Occupied',
                    ),
                    _LegendItem(
                      color: AppColors.primaryBlue,
                      label: 'Selected',
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                // Selected Info
                if (_selectedSpot != null)
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Selected: Spot ${_selectedSpot!.spotNumber}',
                          style: AppTextStyles.body,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedSpot = null;
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSizes.md),
                // Book Button
                CustomButton(
                  text: _selectedSpot != null
                      ? 'BOOK SPOT (${_selectedDuration} min)'
                      : 'SELECT A SPOT',
                  onPressed: _selectedSpot != null ? () => _bookSpot() : () {},
                ),
                const SizedBox(height: AppSizes.sm),
                // Filters
                Text(
                  'Tap a spot to select',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotItem(ParkingSpotModel spot) {
    final isAvailable = spot.status == SpotStatus.available;
    final isSelected = _selectedSpot?.spotId == spot.spotId;
    final isOccupied = spot.status == SpotStatus.occupied;
    final isReserved = spot.status == SpotStatus.reserved;
    final isDisabled = spot.status == SpotStatus.disabled;

    Color backgroundColor;
    Color textColor;

    if (isSelected) {
      backgroundColor = AppColors.primaryBlue;
      textColor = AppColors.backgroundWhite;
    } else if (isDisabled) {
      backgroundColor = AppColors.disabledGray;
      textColor = AppColors.textLight;
    } else if (isOccupied) {
      backgroundColor = AppColors.occupiedRed;
      textColor = AppColors.backgroundWhite;
    } else if (isReserved) {
      backgroundColor = AppColors.reservedYellow;
      textColor = AppColors.backgroundWhite;
    } else {
      backgroundColor = AppColors.availableGreen;
      textColor = AppColors.backgroundWhite;
    }

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() {
                _selectedSpot = spot;
              });
              _showSpotDetails(spot);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isOccupied || isReserved)
                    const Icon(
                      Icons.directions_car,
                      color: AppColors.backgroundWhite,
                      size: 32,
                    )
                  else if (isDisabled)
                    const Icon(
                      Icons.block,
                      color: AppColors.textLight,
                      size: 32,
                    )
                  else
                    Text(
                      spot.spotNumber,
                      style: AppTextStyles.h3.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.backgroundWhite,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSpotDetails(ParkingSpotModel spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.disabledGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Spot ${spot.spotNumber} Details',
                style: AppTextStyles.h2,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                '${_zone!.zoneName}, ${_zone!.campus.name.toUpperCase()} Campus',
                style: AppTextStyles.bodyLight,
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 16,
                    color: AppColors.availableGreen,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    'Available',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Features:',
                style: AppTextStyles.captionBold,
              ),
              const SizedBox(height: AppSizes.sm),
              _DetailRow(icon: Icons.check, text: 'Standard parking spot'),
              ...spot.features.map((feature) => _DetailRow(icon: Icons.check, text: feature)),
              const SizedBox(height: AppSizes.lg),
              Text(
                'Reserve for:',
                style: AppTextStyles.captionBold,
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDuration = 15);
                      setModalState(() {});
                    },
                    child: _DurationChip(
                      label: '15 min',
                      selected: _selectedDuration == 15,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDuration = 30);
                      setModalState(() {});
                    },
                    child: _DurationChip(
                      label: '30 min',
                      selected: _selectedDuration == 30,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDuration = 60);
                      setModalState(() {});
                    },
                    child: _DurationChip(
                      label: '1 hour',
                      selected: _selectedDuration == 60,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedDuration = 120);
                      setModalState(() {});
                    },
                    child: _DurationChip(
                      label: '2 hours',
                      selected: _selectedDuration == 120,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              CustomButton(
                text: 'RESERVE SPOT (${_selectedDuration} min)',
                onPressed: () {
                  Navigator.pop(context);
                  _bookSpot();
                },
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.availableGreen),
          const SizedBox(width: AppSizes.sm),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _DurationChip({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: selected
          ? AppColors.primaryBlue
          : AppColors.backgroundGray,
      labelStyle: TextStyle(
        color: selected ? AppColors.backgroundWhite : AppColors.textDark,
      ),
    );
  }
}
