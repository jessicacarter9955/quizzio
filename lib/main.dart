import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'screens/settings_page.dart';

void main() {
  runApp(const WordweaverApp());
}

class WordweaverApp extends StatelessWidget {
  const WordweaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wordweaver',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
        Locale('it'),
        Locale('fr'),
        Locale('de'),
      ],
      home: const SettingsPage(),
    );
  }
}
