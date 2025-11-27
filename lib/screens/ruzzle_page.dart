import 'package:flutter/material.dart';
import 'package:wordweaver/models/language_pair.dart';
import 'package:wordweaver/models/topic.dart';

class RuzzlePage extends StatefulWidget {
  final LanguagePair languagePair;
  final List<Topic> selectedTopics;

  const RuzzlePage({
    super.key,
    required this.languagePair,
    required this.selectedTopics,
  });

  @override
  State<RuzzlePage> createState() => _RuzzlePageState();
}

class _RuzzlePageState extends State<RuzzlePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruzzle Mode'), centerTitle: true),
      body: const Center(child: Text('Ruzzle game coming soon')),
    );
  }
}
