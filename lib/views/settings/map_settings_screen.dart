import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class MapSettingsScreen extends StatefulWidget {
  const MapSettingsScreen({Key? key}) : super(key: key);

  @override
  State<MapSettingsScreen> createState() => _MapSettingsScreenState();
}

class _MapSettingsScreenState extends State<MapSettingsScreen> {
  bool _isLoading = true;
  bool _showParkingZones = true;
  bool _showTraffic = false;
  bool _autoZoomToCampus = true;
  bool _enableLocationTracking = true;
  String _mapStyle = 'normal';

  @override
  void initState() {
    super.initState();
    _loadMapSettings();
  }

  Future<void> _loadMapSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (doc.exists && doc.data()?['map_settings'] != null) {
          final settings = doc.data()!['map_settings'] as Map<String, dynamic>;
          setState(() {
            _showParkingZones = settings['show_parking_zones'] ?? true;
            _showTraffic = settings['show_traffic'] ?? false;
            _autoZoomToCampus = settings['auto_zoom_to_campus'] ?? true;
            _enableLocationTracking = settings['enable_location_tracking'] ?? true;
            _mapStyle = settings['map_style'] ?? 'normal';
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load settings: $e'),
              backgroundColor: AppColors.occupiedRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _saveMapSettings() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'map_settings': {
            'show_parking_zones': _showParkingZones,
            'show_traffic': _showTraffic,
            'auto_zoom_to_campus': _autoZoomToCampus,
            'enable_location_tracking': _enableLocationTracking,
            'map_style': _mapStyle,
          },
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map settings saved'),
              backgroundColor: AppColors.availableGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save settings: $e'),
              backgroundColor: AppColors.occupiedRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Options',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _SettingTile(
                    title: 'Show Parking Zones',
                    subtitle: 'Display parking zones on the map',
                    value: _showParkingZones,
                    onChanged: (value) {
                      setState(() => _showParkingZones = value);
                      _saveMapSettings();
                    },
                  ),
                  _SettingTile(
                    title: 'Show Traffic',
                    subtitle: 'Display real-time traffic information',
                    value: _showTraffic,
                    onChanged: (value) {
                      setState(() => _showTraffic = value);
                      _saveMapSettings();
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    'Navigation',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _SettingTile(
                    title: 'Auto-Zoom to Campus',
                    subtitle: 'Automatically zoom to selected campus',
                    value: _autoZoomToCampus,
                    onChanged: (value) {
                      setState(() => _autoZoomToCampus = value);
                      _saveMapSettings();
                    },
                  ),
                  _SettingTile(
                    title: 'Enable Location Tracking',
                    subtitle: 'Track your current location on map',
                    value: _enableLocationTracking,
                    onChanged: (value) {
                      setState(() => _enableLocationTracking = value);
                      _saveMapSettings();
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Text(
                    'Map Style',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _MapStyleOption(
                    label: 'Normal',
                    value: 'normal',
                    groupValue: _mapStyle,
                    onChanged: (value) {
                      setState(() => _mapStyle = value!);
                      _saveMapSettings();
                    },
                  ),
                  _MapStyleOption(
                    label: 'Satellite',
                    value: 'satellite',
                    groupValue: _mapStyle,
                    onChanged: (value) {
                      setState(() => _mapStyle = value!);
                      _saveMapSettings();
                    },
                  ),
                  _MapStyleOption(
                    label: 'Hybrid',
                    value: 'hybrid',
                    groupValue: _mapStyle,
                    onChanged: (value) {
                      setState(() => _mapStyle = value!);
                      _saveMapSettings();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: SwitchListTile(
        title: Text(title, style: AppTextStyles.body),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
    );
  }
}

class _MapStyleOption extends StatelessWidget {
  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  const _MapStyleOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: RadioListTile<String>(
        title: Text(label, style: AppTextStyles.body),
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: AppColors.primaryBlue,
      ),
    );
  }
}
