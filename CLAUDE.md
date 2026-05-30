# SmartAlarm

Calendar-aware alarm app that won't dismiss until the user physically leaves home.

## Tech Stack
- Flutter 3.44.0 (iOS + Android)
- Provider for state management
- SharedPreferences + Hive for local storage
- flutter_local_notifications + alarm package for alarms
- geolocator for GPS/geofencing
- device_calendar for calendar access
- RevenueCat (purchases_flutter) for subscriptions

## Build & Run
```bash
flutter pub get
flutter run -d <device_id>    # iOS sim: 47337519-D4FC-4A5D-9C20-CB6FC13D4BC1
flutter analyze               # Check for errors
flutter build web             # Quick compile check
```

## Project Structure
```
lib/
├── main.dart
├── core/          # Constants, entitlement service
├── models/        # AlarmModel, HomeLocation
├── services/      # Location, Calendar, AlarmScheduler, AlarmService
├── features/
│   ├── alarm/     # Home screen, firing screen
│   ├── calendar/  # Calendar sync screen
│   ├── onboarding/# Welcome + set home location
│   └── settings/  # All user preferences
└── widgets/       # Shared widgets (empty for now)
```

## iOS Deployment Target
Set to 15.0 (in Podfile and project.pbxproj). Don't lower it — plugins require it.

## Premium/Paywall Bypass
In debug mode, all premium features are unlocked. See `lib/core/entitlement.dart`.
