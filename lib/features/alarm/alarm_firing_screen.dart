import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/alarm_model.dart';
import '../../models/home_location.dart';
import '../../services/location_service.dart';
import '../../core/constants.dart';

class AlarmFiringScreen extends StatefulWidget {
  final AlarmModel alarm;

  const AlarmFiringScreen({super.key, required this.alarm});

  @override
  State<AlarmFiringScreen> createState() => _AlarmFiringScreenState();
}

class _AlarmFiringScreenState extends State<AlarmFiringScreen>
    with TickerProviderStateMixin {
  final LocationService _locationService = LocationService();
  bool _isOutsideHome = false;
  bool _canDismiss = false;
  bool _isSnoozed = false;
  bool _locationUnavailable = false;
  Timer? _locationTimeoutTimer;
  Timer? _snoozeTimer;
  late AnimationController _pulseController;
  int _currentSnoozeDuration = AppConstants.defaultSnoozeDurationMinutes;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    if (widget.alarm.type == AlarmType.locationGated) {
      _startLocationMonitoring();
    } else {
      _canDismiss = true;
    }
  }

  Future<void> _startLocationMonitoring() async {
    final prefs = await SharedPreferences.getInstance();
    final homeJson = prefs.getString('home_location');
    if (homeJson == null) {
      setState(() => _canDismiss = true);
      return;
    }

    final home = HomeLocation.fromJson(jsonDecode(homeJson));
    final timeoutMinutes = prefs.getInt('location_timeout_minutes') ??
        AppConstants.defaultLocationTimeoutMinutes;

    _locationTimeoutTimer = Timer(Duration(minutes: timeoutMinutes), () {
      setState(() {
        _locationUnavailable = true;
        _canDismiss = true;
      });
    });

    _locationService.startMonitoring(
      home: home,
      onExitConfirmed: () {
        _locationTimeoutTimer?.cancel();
        setState(() {
          _isOutsideHome = true;
          _canDismiss = true;
        });
      },
      onReturned: () {
        setState(() {
          _isOutsideHome = false;
          _canDismiss = false;
        });
      },
    );
  }

  void _snooze() {
    final alarmId = widget.alarm.id.hashCode.abs() % 2147483647;
    Alarm.stop(alarmId);

    setState(() {
      _isSnoozed = true;
    });

    _snoozeTimer = Timer(Duration(minutes: _currentSnoozeDuration), () {
      // Re-ring after snooze
      Alarm.set(
        alarmSettings: AlarmSettings(
          id: alarmId,
          dateTime: DateTime.now().add(const Duration(seconds: 1)),
          assetAudioPath: 'assets/alarm_sound.mp3',
          vibrate: true,
          volumeSettings: const VolumeSettings.fixed(volume: 0.8),
          loopAudio: true,
          notificationSettings: NotificationSettings(
            title: widget.alarm.type == AlarmType.locationGated
                ? 'Time to leave!'
                : 'Wake up!',
            body: widget.alarm.eventTitle ?? 'SmartAlarm',
          ),
        ),
      );
      setState(() => _isSnoozed = false);
    });

    if (widget.alarm.snoozeMode == SnoozeMode.progressive) {
      _currentSnoozeDuration = (_currentSnoozeDuration * 0.7).round().clamp(2, 60);
    }
  }

  void _dismiss() {
    _locationService.stopMonitoring();
    _locationTimeoutTimer?.cancel();
    _snoozeTimer?.cancel();
    Alarm.stop(widget.alarm.id.hashCode.abs() % 2147483647);
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _locationService.stopMonitoring();
    _locationTimeoutTimer?.cancel();
    _snoozeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSnoozed) {
      return _buildSnoozedView(context);
    }
    return _buildAlarmView(context);
  }

  Widget _buildAlarmView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: child,
                  );
                },
                child: const Icon(
                  Icons.alarm,
                  size: 80,
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _formatTime(widget.alarm.triggerTime),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (widget.alarm.eventTitle != null)
                Text(
                  widget.alarm.eventTitle!,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
              if (widget.alarm.eventLocation != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white54, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.alarm.eventLocation!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white54,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 48),
              if (widget.alarm.type == AlarmType.locationGated)
                _buildLocationStatus(context),
              const SizedBox(height: 48),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStatus(BuildContext context) {
    if (_locationUnavailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Location unavailable. Dismiss allowed after timeout.',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    if (_isOutsideHome) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You\'ve left home! You can dismiss the alarm.',
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.home, color: Colors.redAccent),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Leave home to dismiss this alarm.',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _canDismiss ? _dismiss : null,
            style: FilledButton.styleFrom(
              backgroundColor: _canDismiss ? Colors.green : Colors.grey[800],
            ),
            child: Text(
              _canDismiss ? 'Dismiss' : 'Leave home to dismiss',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _snooze,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white38),
            ),
            child: Text(
              'Snooze ($_currentSnoozeDuration min)',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ),
        ),
        if (widget.alarm.id.startsWith('test_')) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _dismiss,
              child: const Text(
                'Force Dismiss (Test Only)',
                style: TextStyle(color: Colors.white38),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSnoozedView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.snooze, size: 64, color: Colors.white38),
              const SizedBox(height: 24),
              Text(
                'Snoozed',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Alarm will ring again in $_currentSnoozeDuration minutes',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white38,
                    ),
              ),
              if (widget.alarm.eventTitle != null) ...[
                const SizedBox(height: 24),
                Text(
                  widget.alarm.eventTitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white30,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
