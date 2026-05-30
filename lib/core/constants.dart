class AppConstants {
  static const String appName = 'SmartAlarm';

  // Geofence
  static const double defaultGeofenceRadiusMeters = 40.0;
  static const int defaultExitConfirmationSeconds = 15;

  // Alarm defaults
  static const int defaultSnoozeDurationMinutes = 10;
  static const int defaultBufferMinutes = 60;
  static const int defaultGetReadyMinutes = 30;

  // Anti-cheat
  static const int defaultLocationTimeoutMinutes = 10;

  // Admin / dev bypass
  static const List<String> adminDeviceIds = [
    // Add your device ID here for free premium access
  ];
}
