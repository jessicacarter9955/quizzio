import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordweaver/screens/settings_page.dart';

void main() {
  testWidgets('SettingsPage smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));

    // Verify that the app bar title is displayed
    expect(find.text('Profile'), findsOneWidget);

    // Verify that the page contains some list tiles
    expect(find.byType(ListTile), findsWidgets);
  });
}
