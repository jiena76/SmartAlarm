import 'package:flutter/material.dart';
import '../../services/calendar_service.dart';
import '../../services/alarm_scheduler.dart';
import '../../services/alarm_service.dart';
import '../../models/alarm_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalendarSyncScreen extends StatefulWidget {
  const CalendarSyncScreen({super.key});

  @override
  State<CalendarSyncScreen> createState() => _CalendarSyncScreenState();
}

class _CalendarSyncScreenState extends State<CalendarSyncScreen> {
  final CalendarService _calendarService = CalendarService();
  final AlarmScheduler _alarmScheduler = AlarmScheduler();
  final AlarmService _alarmService = AlarmService();
  List<CalendarEvent>? _events;
  AlarmModel? _suggestedAlarm;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCalendarEvents();
  }

  Future<void> _loadCalendarEvents() async {
    setState(() => _loading = true);

    final hasPermission = await _calendarService.requestPermission();
    if (!hasPermission) {
      setState(() {
        _error = 'Calendar permission denied. Please grant access in Settings.';
        _loading = false;
      });
      return;
    }

    final events = await _calendarService.getTomorrowFirstEvents();
    final prefs = await SharedPreferences.getInstance();
    final bufferMinutes = prefs.getInt('buffer_minutes') ?? 60;
    final getReadyMinutes = prefs.getInt('get_ready_minutes') ?? 30;

    final alarm = await _alarmScheduler.generateAlarmForTomorrow(
      bufferMinutes: bufferMinutes,
      getReadyMinutes: getReadyMinutes,
    );

    setState(() {
      _events = events;
      _suggestedAlarm = alarm;
      _loading = false;
    });
  }

  Future<void> _confirmAlarm() async {
    if (_suggestedAlarm == null) return;

    await _alarmService.scheduleAlarm(_suggestedAlarm!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarm set for ${_formatTime(_suggestedAlarm!.triggerTime)}',
          ),
        ),
      );
      Navigator.pop(context, _suggestedAlarm);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tomorrow\'s Schedule')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _buildContent(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 48, color: Colors.white38),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadCalendarEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_events != null && _events!.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No events tomorrow. You can set a fallback alarm instead.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_events != null && _events!.isNotEmpty) ...[
            Text(
              'Tomorrow\'s events',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _events!.length,
                itemBuilder: (context, index) {
                  final event = _events![index];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        event.requiresTravel
                            ? Icons.directions_car
                            : Icons.videocam,
                        color: event.requiresTravel
                            ? Colors.deepOrange
                            : Colors.white54,
                      ),
                      title: Text(event.title),
                      subtitle: Text(
                        '${_formatTime(event.start)}'
                        '${event.location != null ? ' • ${event.location}' : ''}',
                      ),
                      trailing: event.requiresTravel
                          ? const Chip(label: Text('Travel'))
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
          if (_suggestedAlarm != null) ...[
            const Divider(height: 32),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggested alarm',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_suggestedAlarm!.triggerTime),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _suggestedAlarm!.type == AlarmType.locationGated
                              ? Icons.location_on
                              : Icons.alarm,
                          size: 16,
                          color: Colors.deepOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _suggestedAlarm!.type == AlarmType.locationGated
                              ? 'Won\'t dismiss until you leave home'
                              : 'Regular alarm',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _confirmAlarm,
              child: const Text('Set This Alarm'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                // TODO: Allow user to adjust time
              },
              child: const Text('Adjust Time'),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
