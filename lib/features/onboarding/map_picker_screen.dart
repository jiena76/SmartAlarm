import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/home_location.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _selectedLocation = const LatLng(37.7749, -122.4194);
  double _radius = 40.0;
  bool _locating = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _locating = false);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locating = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _locating = false;
        });
        _mapController.move(_selectedLocation, 17.0);
      }
    } catch (_) {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _searchError = null);

    try {
      final locations = await locationFromAddress(query)
          .timeout(const Duration(seconds: 10));
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        setState(() {
          _selectedLocation = LatLng(loc.latitude, loc.longitude);
        });
        _mapController.move(_selectedLocation, 17.0);
        FocusScope.of(context).unfocus();
      }
    } on TimeoutException {
      setState(() => _searchError = 'Search timed out. Try again.');
    } catch (_) {
      setState(() => _searchError = 'Address not found. Try a different search.');
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
          // Search bar at top
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search address...',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search),
                            ),
                            onSubmitted: _searchAddress,
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => _searchAddress(_searchController.text),
                        ),
                      ],
                    ),
                    if (_searchError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _searchError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // My location FAB
          Positioned(
            bottom: 120,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _locating ? null : _goToCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          // Bottom card with radius
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
                      'Tap the map or search to set location',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
