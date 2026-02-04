import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'package:wordweaver/screens/settings_page.dart';

void main() {
  testWidgets('SettingsPage smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('es'),
          Locale('it'),
          Locale('fr'),
          Locale('de'),
        ],
        home: SettingsPage(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the app bar title is displayed
    expect(find.text('Profile'), findsOneWidget);

    // Verify that the page contains some list tiles
    expect(find.byType(ListTile), findsWidgets);
  });
}
