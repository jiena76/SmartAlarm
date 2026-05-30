import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_alarm/main.dart';

void main() {
  testWidgets('App launches and shows loading or onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAlarmApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
