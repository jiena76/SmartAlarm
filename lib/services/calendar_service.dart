import 'package:device_calendar/device_calendar.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/home_location.dart';
import 'location_dictionary_service.dart';

class CalendarEvent {
  final String title;
  final DateTime start;
  final String? location;
  final bool requiresTravel;
  final bool locationUnknown;

  CalendarEvent({
    required this.title,
    required this.start,
    this.location,
    required this.requiresTravel,
    this.locationUnknown = false,
  });
}

class CalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  final LocationDictionaryService _dictionary = LocationDictionaryService();

  static const _videoCallPatterns = [
    'zoom.us',
    'meet.google.com',
    'teams.microsoft.com',
    'chime.aws',
    'webex.com',
  ];

  Future<bool> requestPermission() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && result.data == true;
  }

  Future<List<CalendarEvent>> getTomorrowFirstEvents() async {
    final calendars = await _plugin.retrieveCalendars();
    if (!calendars.isSuccess || calendars.data == null) return [];

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfDay = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final allEvents = <CalendarEvent>[];

    for (final calendar in calendars.data!) {
      final events = await _plugin.retrieveEvents(
        calendar.id,
        RetrieveEventsParams(startDate: startOfDay, endDate: endOfDay),
      );

      if (events.isSuccess && events.data != null) {
        for (final event in events.data!) {
          if (event.start == null) continue;
          final travelResult = await _requiresTravel(event.location);
          allEvents.add(CalendarEvent(
            title: event.title ?? 'Untitled',
            start: event.start!.toUtc().toLocal(),
            location: event.location,
            requiresTravel: travelResult.requiresTravel,
            locationUnknown: travelResult.unknown,
          ));
        }
      }
    }

    allEvents.sort((a, b) => a.start.compareTo(b.start));
    return allEvents;
  }

  Future<_TravelResult> _requiresTravel(String? location) async {
    if (location == null || location.isEmpty) {
      return _TravelResult(requiresTravel: false, unknown: false);
    }

    final lower = location.toLowerCase();

    for (final pattern in _videoCallPatterns) {
      if (lower.contains(pattern)) {
        return _TravelResult(requiresTravel: false, unknown: false);
      }
    }

    // Check learned dictionary
    final learned = await _dictionary.lookup(location);
    if (learned != null) {
      return _TravelResult(requiresTravel: learned, unknown: false);
    }

    // Try to geocode and compare distance to home
    final home = await _getHomeLocation();
    if (home != null) {
      try {
        final locations = await geo.locationFromAddress(location)
            .timeout(const Duration(seconds: 5));
        if (locations.isNotEmpty) {
          final eventLat = locations.first.latitude;
          final eventLng = locations.first.longitude;
          final isNearHome = !home.isOutside(eventLat, eventLng);
          if (isNearHome) {
            return _TravelResult(requiresTravel: false, unknown: false);
          }
          return _TravelResult(requiresTravel: true, unknown: false);
        }
      } catch (_) {
        // Geocoding failed — treat as unknown
      }
    }

    // Can't determine — mark as unknown and ask user
    return _TravelResult(requiresTravel: true, unknown: true);
  }

  Future<HomeLocation?> _getHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('home_location');
    if (json == null) return null;
    return HomeLocation.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }
}

class _TravelResult {
  final bool requiresTravel;
  final bool unknown;

  _TravelResult({required this.requiresTravel, required this.unknown});
}
