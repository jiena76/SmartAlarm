import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/home_location.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(37.7749, -122.4194); // Default SF
  double _radius = 40.0;
  bool _initialLocationSet = false;

  @override
  void initState() {
    super.initState();
    _tryGetCurrentLocation();
  }

  Future<void> _tryGetCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 5));
      if (mounted && !_initialLocationSet) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _initialLocationSet = true;
        });
        _mapController.move(_selectedLocation, 17.0);
      }
    } catch (_) {
      // Use default location
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Home Location'),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 17.0,
              onTap: (tapPosition, latLng) {
                setState(() => _selectedLocation = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartalarm.smart_alarm',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _selectedLocation,
                    radius: _radius,
                    useRadiusInMeter: true,
                    color: Colors.deepOrange.withValues(alpha: 0.2),
                    borderColor: Colors.deepOrange,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.home,
                      color: Colors.deepOrange,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap the map to set your home location',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Radius:'),
                        Expanded(
                          child: Slider(
                            value: _radius,
                            min: 20,
                            max: 100,
                            divisions: 16,
                            label: '${_radius.toInt()}m',
                            onChanged: (value) {
                              setState(() => _radius = value);
                            },
                          ),
                        ),
                        Text('${_radius.toInt()}m'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final home = HomeLocation(
      latitude: _selectedLocation.latitude,
      longitude: _selectedLocation.longitude,
      radiusMeters: _radius,
      label: 'Home',
    );
    Navigator.pop(context, home);
  }
}
