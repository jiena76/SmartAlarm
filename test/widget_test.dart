import 'package:flutter_test/flutter_test.dart';
import 'package:smart_alarm/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAlarmApp());
    expect(find.text('SmartAlarm'), findsOneWidget);
  });
}
