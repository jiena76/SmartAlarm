import 'package:flutter/material.dart';
import '../../models/alarm_model.dart';
import '../../services/alarm_service.dart';
import '../calendar/calendar_sync_screen.dart';
import '../settings/settings_screen.dart';
import 'alarm_firing_screen.dart';

class AlarmHomeScreen extends StatefulWidget {
  const AlarmHomeScreen({super.key});

  @override
  State<AlarmHomeScreen> createState() => _AlarmHomeScreenState();
}

class _AlarmHomeScreenState extends State<AlarmHomeScreen> {
  final AlarmService _alarmService = AlarmService();
  List<AlarmModel> _alarms = [];

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final alarms = await _alarmService.getScheduledAlarms();
    setState(() => _alarms = alarms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartAlarm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildNextAlarmCard(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            if (_alarms.length > 1) ...[
              const SizedBox(height: 24),
              Text('Upcoming', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(child: _buildAlarmList(context)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNextAlarmCard(BuildContext context) {
    if (_alarms.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(
                Icons.alarm_off,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No alarm set',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Sync your calendar or set a manual alarm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    final alarm = _alarms.first;
    final timeStr =
        '${alarm.triggerTime.hour.toString().padLeft(2, '0')}:'
        '${alarm.triggerTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => _testAlarm(alarm),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    alarm.type == AlarmType.locationGated
                        ? Icons.location_on
                        : Icons.alarm,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    alarm.type == AlarmType.locationGated
                        ? 'Location-gated'
                        : 'Regular alarm',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () async {
                      await _alarmService.cancelAlarm(alarm.id);
                      _loadAlarms();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                timeStr,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              if (alarm.eventTitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  alarm.eventTitle!,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
              if (alarm.eventLocation != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      alarm.eventLocation!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final result = await Navigator.push<AlarmModel>(
              context,
              MaterialPageRoute(builder: (_) => const CalendarSyncScreen()),
            );
            if (result != null) _loadAlarms();
          },
          icon: const Icon(Icons.calendar_month),
          label: const Text('Sync Calendar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showManualAlarmPicker(context),
          icon: const Icon(Icons.add_alarm),
          label: const Text('Set Manual Alarm'),
        ),
      ],
    );
  }

  Widget _buildAlarmList(BuildContext context) {
    return ListView.builder(
      itemCount: _alarms.length - 1,
      itemBuilder: (context, index) {
        final alarm = _alarms[index + 1];
        final timeStr =
            '${alarm.triggerTime.hour.toString().padLeft(2, '0')}:'
            '${alarm.triggerTime.minute.toString().padLeft(2, '0')}';
        return ListTile(
          leading: Icon(
            alarm.type == AlarmType.locationGated
                ? Icons.location_on
                : Icons.alarm,
            color: Colors.deepOrange,
          ),
          title: Text(timeStr),
          subtitle: Text(alarm.eventTitle ?? 'Manual alarm'),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await _alarmService.cancelAlarm(alarm.id);
              _loadAlarms();
            },
          ),
        );
      },
    );
  }

  void _testAlarm(AlarmModel alarm) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AlarmFiringScreen(alarm: alarm)),
    );
  }

  Future<void> _showManualAlarmPicker(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now().replacing(
        hour: (TimeOfDay.now().hour + 8) % 24,
      ),
    );

    if (time == null || !mounted) return;

    final now = DateTime.now();
    var triggerTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (triggerTime.isBefore(now)) {
      triggerTime = triggerTime.add(const Duration(days: 1));
    }

    final alarm = AlarmModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      triggerTime: triggerTime,
      type: AlarmType.locationGated,
      eventTitle: 'Manual alarm',
    );

    await _alarmService.scheduleAlarm(alarm);
    _loadAlarms();
  }
}
