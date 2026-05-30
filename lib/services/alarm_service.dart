import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'dart:convert';
import '../models/alarm_model.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._();
  factory AlarmService() => _instance;
  AlarmService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<void> scheduleAlarm(AlarmModel alarm) async {
    await _saveAlarm(alarm);

    await _notifications.zonedSchedule(
      id: alarm.id.hashCode,
      title: alarm.type == AlarmType.locationGated
          ? 'Time to leave!'
          : 'Wake up!',
      body: alarm.eventTitle ?? 'Alarm',
      scheduledDate: _convertToTZDateTime(alarm.triggerTime),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarms',
          channelDescription: 'SmartAlarm notifications',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelAlarm(String alarmId) async {
    await _notifications.cancel(id: alarmId.hashCode);
    await _removeAlarm(alarmId);
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('scheduled_alarms');
  }

  Future<List<AlarmModel>> getScheduledAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getStringList('scheduled_alarms') ?? [];
    return alarmsJson.map((json) => _alarmFromJson(jsonDecode(json))).toList();
  }

  Future<void> _saveAlarm(AlarmModel alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = prefs.getStringList('scheduled_alarms') ?? [];
    alarms.add(jsonEncode(_alarmToJson(alarm)));
    await prefs.setStringList('scheduled_alarms', alarms);
  }

  Future<void> _removeAlarm(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final alarms = prefs.getStringList('scheduled_alarms') ?? [];
    alarms.removeWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == alarmId;
    });
    await prefs.setStringList('scheduled_alarms', alarms);
  }

  Map<String, dynamic> _alarmToJson(AlarmModel alarm) => {
        'id': alarm.id,
        'triggerTime': alarm.triggerTime.toIso8601String(),
        'type': alarm.type.index,
        'eventTitle': alarm.eventTitle,
        'eventLocation': alarm.eventLocation,
        'snoozeMode': alarm.snoozeMode.index,
        'volumeMode': alarm.volumeMode.index,
        'snoozeDurationMinutes': alarm.snoozeDurationMinutes,
        'isActive': alarm.isActive,
      };

  AlarmModel _alarmFromJson(Map<String, dynamic> json) => AlarmModel(
        id: json['id'],
        triggerTime: DateTime.parse(json['triggerTime']),
        type: AlarmType.values[json['type']],
        eventTitle: json['eventTitle'],
        eventLocation: json['eventLocation'],
        snoozeMode: SnoozeMode.values[json['snoozeMode'] ?? 0],
        volumeMode: VolumeMode.values[json['volumeMode'] ?? 0],
        snoozeDurationMinutes: json['snoozeDurationMinutes'] ?? 10,
        isActive: json['isActive'] ?? true,
      );

  static tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }
}
