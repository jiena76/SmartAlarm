import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import '../core/constants.dart';
import '../core/entitlement.dart';
import 'calendar_service.dart';

class AlarmScheduler {
  final CalendarService _calendarService = CalendarService();
  final EntitlementService _entitlementService = EntitlementService();

  Future<AlarmModel?> generateAlarmForTomorrow({
    required int bufferMinutes,
    required int getReadyMinutes,
  }) async {
    final events = await _calendarService.getTomorrowFirstEvents();

    if (events.isEmpty) {
      return _getFallbackAlarm();
    }

    final firstEvent = events.first;
    final isPremium = await _entitlementService.hasPremium();

    if (!firstEvent.requiresTravel) {
      // First event is remote — regular alarm based on event time
      final triggerTime = firstEvent.start.subtract(Duration(minutes: bufferMinutes));
      return AlarmModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        triggerTime: triggerTime,
        type: AlarmType.regular,
        eventTitle: firstEvent.title,
        eventLocation: firstEvent.location,
      );
    }

    // First event requires travel — location-gated alarm
    final Duration totalBuffer;
    if (isPremium && firstEvent.location != null) {
      final commuteMinutes = await _estimateCommute(firstEvent.location!);
      totalBuffer = Duration(minutes: commuteMinutes + getReadyMinutes);
    } else {
      totalBuffer = Duration(minutes: bufferMinutes);
    }

    final triggerTime = firstEvent.start.subtract(totalBuffer);

    return AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      triggerTime: triggerTime,
      type: AlarmType.locationGated,
      eventTitle: firstEvent.title,
      eventLocation: firstEvent.location,
    );
  }

  Future<AlarmModel?> _getFallbackAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('fallback_alarm_enabled') ?? false;
    if (!enabled) return null;

    final hour = prefs.getInt('fallback_alarm_hour') ?? 7;
    final minute = prefs.getInt('fallback_alarm_minute') ?? 0;

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final triggerTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      hour,
      minute,
    );

    return AlarmModel(
      id: 'fallback_${triggerTime.millisecondsSinceEpoch}',
      triggerTime: triggerTime,
      type: AlarmType.regular,
      eventTitle: 'Fallback alarm',
    );
  }

  Future<int> _estimateCommute(String destination) async {
    // TODO: Platform-specific maps API call
    // Apple Maps on iOS, Google Maps on Android
    return AppConstants.defaultBufferMinutes;
  }
}
