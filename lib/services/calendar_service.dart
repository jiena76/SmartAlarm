import 'package:device_calendar/device_calendar.dart';

class CalendarEvent {
  final String title;
  final DateTime start;
  final String? location;
  final bool requiresTravel;

  CalendarEvent({
    required this.title,
    required this.start,
    this.location,
    required this.requiresTravel,
  });
}

class CalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();

  static const _videoCallPatterns = [
    'zoom.us',
    'meet.google.com',
    'teams.microsoft.com',
    'chime.aws',
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
          allEvents.add(CalendarEvent(
            title: event.title ?? 'Untitled',
            start: event.start!.toUtc().toLocal(),
            location: event.location,
            requiresTravel: _requiresTravel(event.location),
          ));
        }
      }
    }

    allEvents.sort((a, b) => a.start.compareTo(b.start));
    return allEvents;
  }

  bool _requiresTravel(String? location) {
    if (location == null || location.isEmpty) return false;

    final lower = location.toLowerCase();

    for (final pattern in _videoCallPatterns) {
      if (lower.contains(pattern)) return false;
    }

    // Has a location that's not a video call link — likely requires travel
    // TODO: Compare against home location and learned dictionary
    return true;
  }
}
