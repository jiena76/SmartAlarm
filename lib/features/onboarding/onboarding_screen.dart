import 'package:flutter/material.dart';
import 'set_home_location_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.alarm, size: 80, color: Colors.deepOrange),
              const SizedBox(height: 32),
              Text(
                'SmartAlarm',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'The alarm that makes sure you actually leave for work.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () => _setupLocation(context),
                icon: const Icon(Icons.location_on),
                label: const Text('Set Your Home Location'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _setupLocation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetHomeLocationScreen()),
    );
  }
}
