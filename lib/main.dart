import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wordweaver/l10n/app_localizations.dart';
import 'package:wordweaver/services/theme_service.dart';
import 'package:wordweaver/services/locale_service.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const WordweaverApp());
}

class WordweaverApp extends StatelessWidget {
  const WordweaverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final localeService = LocaleService();

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, localeService]),
      builder: (context, _) {
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
          themeMode: themeService.themeMode,
          locale: localeService.locale,
          home: const HomePage(),
        );
      },
    );
  }
}
