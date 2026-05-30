import 'package:alarm/alarm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/alarm_model.dart';

class AlarmTriggerService {
  static final AlarmTriggerService _instance = AlarmTriggerService._();
  factory AlarmTriggerService() => _instance;
  AlarmTriggerService._();

  Future<void> initialize() async {
    await Alarm.init();
  }

  Future<void> setAlarm(AlarmModel alarm) async {
    final alarmSettings = AlarmSettings(
      id: alarmIdFromString(alarm.id),
      dateTime: alarm.triggerTime,
      assetAudioPath: 'assets/alarm_sound.mp3',
      vibrate: true,
      volumeSettings: alarm.volumeMode == VolumeMode.escalating
          ? VolumeSettings.fade(
              volume: 0.8,
              fadeDuration: const Duration(seconds: 30),
            )
          : const VolumeSettings.fixed(volume: 0.8),
      loopAudio: true,
      notificationSettings: NotificationSettings(
        title: alarm.type == AlarmType.locationGated
            ? 'Time to leave!'
            : 'Wake up!',
        body: alarm.eventTitle ?? 'SmartAlarm',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
    await _saveAlarmMapping(alarm);
  }

  Future<void> cancelAlarm(AlarmModel alarm) async {
    await Alarm.stop(alarmIdFromString(alarm.id));
    await _removeAlarmMapping(alarm.id);
  }

  static int alarmIdFromString(String id) {
    // Use last 9 digits of the string's hashCode to avoid collisions
    // while staying within 32-bit int range
    return id.hashCode.abs() % 1000000000;
  }

  Future<void> cancelAll() async {
    await Alarm.stopAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alarm_mappings');
  }

  Future<AlarmModel?> getAlarmModelForId(int alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final mappings = prefs.getStringList('alarm_mappings') ?? [];
    for (final json in mappings) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final model = _alarmFromJson(map);
      if (alarmIdFromString(model.id) == alarmId) {
        return model;
      }
    }
    return null;
  }

  Future<void> _saveAlarmMapping(AlarmModel alarm) async {
    final prefs = await SharedPreferences.getInstance();
    final mappings = prefs.getStringList('alarm_mappings') ?? [];
    mappings.removeWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == alarm.id;
    });
    mappings.add(jsonEncode(_alarmToJson(alarm)));
    await prefs.setStringList('alarm_mappings', mappings);
  }

  Future<void> _removeAlarmMapping(String alarmId) async {
    final prefs = await SharedPreferences.getInstance();
    final mappings = prefs.getStringList('alarm_mappings') ?? [];
    mappings.removeWhere((json) {
      final map = jsonDecode(json);
      return map['id'] == alarmId;
    });
    await prefs.setStringList('alarm_mappings', mappings);
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
}
