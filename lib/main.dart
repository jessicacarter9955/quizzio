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

  // High-contrast lime accents for buttons, chips, icons and progress bars.
  // Keep page surfaces neutral so quiz text stays easy to read.
  static ColorScheme _limeScheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: const Color(0xFFA3E635),
      brightness: brightness,
    ).copyWith(
      primary: const Color(0xFFA3E635),
      onPrimary: const Color(0xFF1B2909),
      primaryContainer: dark
          ? const Color(0xFF354B12)
          : const Color(0xFFE8F8C7),
      onPrimaryContainer: dark
          ? const Color(0xFFE8F8C7)
          : const Color(0xFF263B0C),
      secondary: const Color(0xFF86C71D),
      onSecondary: const Color(0xFF152507),
      tertiary: const Color(0xFF36A853),
      onTertiary: Colors.white,
      surfaceTint: const Color(0xFFA3E635),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();
    final localeService = LocaleService();

    return ListenableBuilder(
      listenable: Listenable.merge([themeService, localeService]),
      builder: (context, _) {
        final lightScheme = _limeScheme(Brightness.light);
        final darkScheme = _limeScheme(Brightness.dark);

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
          theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
          darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),
          themeMode: themeService.themeMode,
          locale: localeService.locale,
          home: const HomePage(),
        );
      },
    );
  }
}

