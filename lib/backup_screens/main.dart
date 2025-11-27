import 'package:flutter/material.dart';
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
      home: const SettingsPage(),
    );
  }
}
