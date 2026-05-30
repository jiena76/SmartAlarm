import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/home_location.dart';
import '../core/constants.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _exitStartTime;
  final int exitConfirmationSeconds;

  LocationService({
    this.exitConfirmationSeconds = AppConstants.defaultExitConfirmationSeconds,
  });

  Future<bool> checkPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Fall back to last known position
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  void startMonitoring({
    required HomeLocation home,
    required void Function() onExitConfirmed,
    required void Function() onReturned,
  }) {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      final isOutside = home.isOutside(position.latitude, position.longitude);

      if (isOutside) {
        _exitStartTime ??= DateTime.now();
        final elapsed = DateTime.now().difference(_exitStartTime!).inSeconds;
        if (elapsed >= exitConfirmationSeconds) {
          onExitConfirmed();
        }
      } else {
        _exitStartTime = null;
        onReturned();
      }
    });
  }

  void stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _exitStartTime = null;
  }
}
