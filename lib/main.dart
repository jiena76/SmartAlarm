import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/alarm/alarm_home_screen.dart';
import 'features/alarm/alarm_firing_screen.dart';
import 'services/location_service.dart';
import 'services/calendar_service.dart';
import 'services/alarm_scheduler.dart';
import 'services/alarm_service.dart';
import 'services/alarm_trigger_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlarmService().initialize();
  await AlarmTriggerService().initialize();
  runApp(const SmartAlarmApp());
}

class SmartAlarmApp extends StatelessWidget {
  const SmartAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => LocationService()),
        Provider(create: (_) => CalendarService()),
        Provider(create: (_) => AlarmScheduler()),
        Provider(create: (_) => AlarmTriggerService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'SmartAlarm',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const AppEntry(),
      ),
    );
  }
}

class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _onboardingComplete;
  StreamSubscription<AlarmSet>? _alarmSubscription;
  final Set<int> _handledAlarmIds = {};

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    _listenForAlarms();
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    });
  }

  void _listenForAlarms() {
    _alarmSubscription = Alarm.ringing.listen((alarmSet) async {
      for (final alarmSettings in alarmSet.alarms) {
        if (_handledAlarmIds.contains(alarmSettings.id)) continue;
        _handledAlarmIds.add(alarmSettings.id);

        final alarmModel =
            await AlarmTriggerService().getAlarmModelForId(alarmSettings.id);
        if (alarmModel != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AlarmFiringScreen(alarm: alarmModel),
            ),
          );
        }
      }

      if (alarmSet.alarms.isEmpty) {
        _handledAlarmIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_onboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _onboardingComplete! ? const AlarmHomeScreen() : const OnboardingScreen();
  }
}
