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
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      return requested == LocationPermission.always ||
          requested == LocationPermission.whileInUse;
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
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
