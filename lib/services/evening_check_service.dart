import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/alarm_model.dart';
import 'alarm_scheduler.dart';
import 'alarm_service.dart';
import 'alarm_trigger_service.dart';

class EveningCheckService {
  final AlarmScheduler _scheduler = AlarmScheduler();
  final AlarmService _alarmService = AlarmService();
  final AlarmTriggerService _triggerService = AlarmTriggerService();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> runEveningCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final bufferMinutes = prefs.getInt('buffer_minutes') ?? 60;
    final getReadyMinutes = prefs.getInt('get_ready_minutes') ?? 30;
    final autoMode = prefs.getBool('auto_mode') ?? true;

    final alarm = await _scheduler.generateAlarmForTomorrow(
      bufferMinutes: bufferMinutes,
      getReadyMinutes: getReadyMinutes,
    );

    if (alarm == null) return;

    if (autoMode) {
      await _alarmService.scheduleAlarm(alarm);
      await _triggerService.setAlarm(alarm);
      await _showInfoNotification(alarm);
    } else {
      await _showConfirmNotification(alarm);
    }
  }

  Future<void> _showInfoNotification(AlarmModel alarm) async {
    final timeStr =
        '${alarm.triggerTime.hour.toString().padLeft(2, '0')}:'
        '${alarm.triggerTime.minute.toString().padLeft(2, '0')}';

    await _notifications.show(
      id: 9999,
      title: 'Alarm set for $timeStr',
      body: alarm.eventTitle != null
          ? '${alarm.eventTitle} — ${alarm.type.name == 'locationGated' ? 'leave home to dismiss' : 'regular alarm'}'
          : 'SmartAlarm ready for tomorrow',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_check',
          'Evening Check',
          channelDescription: 'Alarm confirmation notifications',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> _showConfirmNotification(AlarmModel alarm) async {
    final timeStr =
        '${alarm.triggerTime.hour.toString().padLeft(2, '0')}:'
        '${alarm.triggerTime.minute.toString().padLeft(2, '0')}';

    await _notifications.show(
      id: 9998,
      title: 'Set alarm for $timeStr tomorrow?',
      body: alarm.eventTitle != null
          ? '${alarm.eventTitle} — tap to open SmartAlarm and confirm'
          : 'Open SmartAlarm to confirm or adjust',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_check',
          'Evening Check',
          channelDescription: 'Alarm confirmation notifications',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  Future<void> scheduleEveningCheck() async {
    final now = DateTime.now();
    var eveningTime = DateTime(now.year, now.month, now.day, 21, 0);
    if (eveningTime.isBefore(now)) {
      eveningTime = eveningTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: 8888,
      title: 'SmartAlarm',
      body: 'Checking tomorrow\'s schedule...',
      scheduledDate: tz.TZDateTime.from(eveningTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'evening_check',
          'Evening Check',
          channelDescription: 'Triggers evening alarm check',
          importance: Importance.low,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
