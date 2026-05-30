import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../models/alarm_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _bufferMinutes;
  late int _getReadyMinutes;
  late int _snoozeDuration;
  late int _locationTimeoutMinutes;
  SnoozeMode _snoozeMode = SnoozeMode.fixed;
  VolumeMode _volumeMode = VolumeMode.fixed;
  bool _autoMode = true;
  bool _fallbackAlarmEnabled = false;
  TimeOfDay _fallbackAlarmTime = const TimeOfDay(hour: 7, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bufferMinutes = prefs.getInt('buffer_minutes') ?? AppConstants.defaultBufferMinutes;
      _getReadyMinutes = prefs.getInt('get_ready_minutes') ?? AppConstants.defaultGetReadyMinutes;
      _snoozeDuration = prefs.getInt('snooze_duration') ?? AppConstants.defaultSnoozeDurationMinutes;
      _locationTimeoutMinutes = prefs.getInt('location_timeout_minutes') ?? AppConstants.defaultLocationTimeoutMinutes;
      _snoozeMode = SnoozeMode.values[prefs.getInt('snooze_mode') ?? 0];
      _volumeMode = VolumeMode.values[prefs.getInt('volume_mode') ?? 0];
      _autoMode = prefs.getBool('auto_mode') ?? true;
      _fallbackAlarmEnabled = prefs.getBool('fallback_alarm_enabled') ?? false;
      final fallbackHour = prefs.getInt('fallback_alarm_hour') ?? 7;
      final fallbackMinute = prefs.getInt('fallback_alarm_minute') ?? 0;
      _fallbackAlarmTime = TimeOfDay(hour: fallbackHour, minute: fallbackMinute);
      _loading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader('Alarm Generation'),
          SwitchListTile(
            title: const Text('Auto-generate alarms'),
            subtitle: Text(_autoMode
                ? 'Alarms created automatically from calendar'
                : 'You\'ll get a notification to confirm each alarm'),
            value: _autoMode,
            onChanged: (value) {
              setState(() => _autoMode = value);
              _saveSetting('auto_mode', value);
            },
          ),
          const Divider(),
          _buildSectionHeader('Fallback Alarm'),
          SwitchListTile(
            title: const Text('Default alarm on quiet days'),
            subtitle: Text(_fallbackAlarmEnabled
                ? 'Rings at ${_fallbackAlarmTime.format(context)} when no travel events'
                : 'No alarm on days without travel events'),
            value: _fallbackAlarmEnabled,
            onChanged: (value) {
              setState(() => _fallbackAlarmEnabled = value);
              _saveSetting('fallback_alarm_enabled', value);
            },
          ),
          if (_fallbackAlarmEnabled)
            ListTile(
              title: const Text('Fallback alarm time'),
              subtitle: Text(_fallbackAlarmTime.format(context)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _fallbackAlarmTime,
                );
                if (time != null) {
                  setState(() => _fallbackAlarmTime = time);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('fallback_alarm_hour', time.hour);
                  await prefs.setInt('fallback_alarm_minute', time.minute);
                }
              },
            ),
          const Divider(),
          _buildSectionHeader('Timing'),
          ListTile(
            title: const Text('Wake-up buffer'),
            subtitle: Text('$_bufferMinutes minutes before event'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker(
              title: 'Minutes before event',
              value: _bufferMinutes,
              min: 15,
              max: 180,
              step: 15,
              onChanged: (v) {
                setState(() => _bufferMinutes = v);
                _saveSetting('buffer_minutes', v);
              },
            ),
          ),
          ListTile(
            title: const Text('Get-ready time (Premium)'),
            subtitle: Text('$_getReadyMinutes minutes to prepare'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker(
              title: 'Minutes to get ready',
              value: _getReadyMinutes,
              min: 10,
              max: 120,
              step: 5,
              onChanged: (v) {
                setState(() => _getReadyMinutes = v);
                _saveSetting('get_ready_minutes', v);
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader('Snooze'),
          ListTile(
            title: const Text('Snooze duration'),
            subtitle: Text('$_snoozeDuration minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker(
              title: 'Snooze duration (minutes)',
              value: _snoozeDuration,
              min: 1,
              max: 30,
              step: 1,
              onChanged: (v) {
                setState(() => _snoozeDuration = v);
                _saveSetting('snooze_duration', v);
              },
            ),
          ),
          _buildEnumTile(
            title: 'Snooze mode',
            subtitle: _snoozeMode == SnoozeMode.fixed
                ? 'Fixed duration each time'
                : 'Gets shorter each snooze',
            options: ['Fixed', 'Progressive'],
            selectedIndex: _snoozeMode.index,
            onChanged: (index) {
              setState(() => _snoozeMode = SnoozeMode.values[index]);
              _saveSetting('snooze_mode', index);
            },
          ),
          const Divider(),
          _buildSectionHeader('Alarm Sound'),
          _buildEnumTile(
            title: 'Volume mode',
            subtitle: _volumeMode == VolumeMode.fixed
                ? 'Consistent volume'
                : 'Starts quiet, gets louder',
            options: ['Fixed', 'Escalating'],
            selectedIndex: _volumeMode.index,
            onChanged: (index) {
              setState(() => _volumeMode = VolumeMode.values[index]);
              _saveSetting('volume_mode', index);
            },
          ),
          const Divider(),
          _buildSectionHeader('Location'),
          ListTile(
            title: const Text('Location timeout'),
            subtitle: Text(
              'Allow dismiss after $_locationTimeoutMinutes min without location',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPicker(
              title: 'Timeout (minutes)',
              value: _locationTimeoutMinutes,
              min: 5,
              max: 60,
              step: 5,
              onChanged: (v) {
                setState(() => _locationTimeoutMinutes = v);
                _saveSetting('location_timeout_minutes', v);
              },
            ),
          ),
          ListTile(
            title: const Text('Update home location'),
            subtitle: const Text('Change where "home" is'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to set home location
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildEnumTile({
    required String title,
    required String subtitle,
    required List<String> options,
    required int selectedIndex,
    required void Function(int) onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: SegmentedButton<int>(
        segments: options
            .asMap()
            .entries
            .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
            .toList(),
        selected: {selectedIndex},
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }

  void _showNumberPicker({
    required String title,
    required int value,
    required int min,
    required int max,
    required int step,
    required void Function(int) onChanged,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        int current = value;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: current.toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: (max - min) ~/ step,
                    label: '$current',
                    onChanged: (v) {
                      setDialogState(() => current = v.round());
                    },
                  ),
                  Text('$current minutes',
                      style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    onChanged(current);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
