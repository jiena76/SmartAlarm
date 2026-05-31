import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CheatLogEntry {
  final DateTime timestamp;
  final String alarmId;
  final String? eventTitle;

  CheatLogEntry({
    required this.timestamp,
    required this.alarmId,
    this.eventTitle,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'alarmId': alarmId,
        'eventTitle': eventTitle,
      };

  factory CheatLogEntry.fromJson(Map<String, dynamic> json) => CheatLogEntry(
        timestamp: DateTime.parse(json['timestamp']),
        alarmId: json['alarmId'],
        eventTitle: json['eventTitle'],
      );
}

class CheatLogService {
  static const _key = 'cheat_log';

  Future<void> logTimeoutDismiss(String alarmId, String? eventTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getEntries();
    entries.add(CheatLogEntry(
      timestamp: DateTime.now(),
      alarmId: alarmId,
      eventTitle: eventTitle,
    ));
    // Keep last 30 entries
    final trimmed = entries.length > 30 ? entries.sublist(entries.length - 30) : entries;
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  Future<List<CheatLogEntry>> getEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => CheatLogEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getThisWeekCount() async {
    final entries = await getEntries();
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return entries.where((e) => e.timestamp.isAfter(weekAgo)).length;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
