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
    if (events.isEmpty) return null;

    final firstEvent = events.first;
    final isPremium = await _entitlementService.hasPremium();

    final Duration totalBuffer;
    if (isPremium && firstEvent.requiresTravel && firstEvent.location != null) {
      // Paid: event time - commute - get ready time
      final commuteMinutes = await _estimateCommute(firstEvent.location!);
      totalBuffer = Duration(minutes: commuteMinutes + getReadyMinutes);
    } else {
      // Free: event time - user's fixed buffer
      totalBuffer = Duration(minutes: bufferMinutes);
    }

    final triggerTime = firstEvent.start.subtract(totalBuffer);

    return AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      triggerTime: triggerTime,
      type: firstEvent.requiresTravel ? AlarmType.locationGated : AlarmType.regular,
      eventTitle: firstEvent.title,
      eventLocation: firstEvent.location,
    );
  }

  Future<int> _estimateCommute(String destination) async {
    // TODO: Platform-specific maps API call
    // Apple Maps on iOS, Google Maps on Android
    return AppConstants.defaultBufferMinutes;
  }
}
