import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../services/location_service.dart';
import '../../models/home_location.dart';
import '../alarm/alarm_home_screen.dart';

class SetHomeLocationScreen extends StatefulWidget {
  const SetHomeLocationScreen({super.key});

  @override
  State<SetHomeLocationScreen> createState() => _SetHomeLocationScreenState();
}

class _SetHomeLocationScreenState extends State<SetHomeLocationScreen> {
  HomeLocation? _selectedLocation;
  bool _loading = false;

  Future<void> _useCurrentLocation() async {
    setState(() => _loading = true);

    final locationService = context.read<LocationService>();
    final position = await locationService.getCurrentPosition();

    if (position != null) {
      setState(() {
        _selectedLocation = HomeLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          label: 'Home',
        );
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get location. Please grant permission.')),
        );
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (_selectedLocation == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('home_location', jsonEncode(_selectedLocation!.toJson()));
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AlarmHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Home Location')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Where do you sleep?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The alarm won\'t dismiss until you leave this area.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _loading ? null : _useCurrentLocation,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: const Text('Use Current Location'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Open map picker for manual pin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Map picker coming soon')),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Pick on Map'),
            ),
            const Spacer(),
            if (_selectedLocation != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Home location set:'),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                        '${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Radius: ${_selectedLocation!.radiusMeters.toInt()}m',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saveAndContinue,
                child: const Text('Continue'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
