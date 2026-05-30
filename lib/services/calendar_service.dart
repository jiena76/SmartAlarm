import 'package:device_calendar/device_calendar.dart';
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

    // Has a location but we don't know if it requires travel
    return _TravelResult(requiresTravel: true, unknown: true);
  }
}

class _TravelResult {
  final bool requiresTravel;
  final bool unknown;

  _TravelResult({required this.requiresTravel, required this.unknown});
}
