import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wordweaver/services/quizlab_topics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordweaver/models/topic.dart';

class TopicService extends ChangeNotifier {
  // Singleton instance to ensure consistent state and notifications across screens
  static final TopicService _instance = TopicService._internal();
  factory TopicService() => _instance;

  TopicService._internal() {
    _loadTopics();
  }
  static final List<Topic> _defaultTopics = [
    Topic(id: 'food', name: 'Food & Drink', emoji: '🍔'),
    Topic(id: 'conversation', name: 'Conversation', emoji: '💬'),
    Topic(id: 'body', name: 'Body', emoji: '💪'),
    Topic(
      id: 'family_and_relationships',
      name: 'Family & Relationships',
      emoji: '👨‍👩‍👧‍👦',
    ),
    Topic(id: 'health', name: 'Health', emoji: '🏥'),
    Topic(id: 'home_and_rooms', name: 'Home & Rooms', emoji: '🏠'),
    Topic(id: 'services', name: 'Services', emoji: '🛠️'),
    Topic(id: 'countries', name: 'Countries', emoji: '🌍'),
    Topic(id: 'unit_of_measurement', name: 'Measurements', emoji: '📏'),
    Topic(id: 'fauna', name: 'Animals', emoji: '🐾'),
    Topic(id: 'emotions_and_senses', name: 'Emotions & Senses', emoji: '😊'),
    Topic(id: 'sports', name: 'Sports', emoji: '🏅'),
    Topic(id: 'hobbies', name: 'Hobbies & Leisure', emoji: '🎮'),
    Topic(id: 'school', name: 'School', emoji: '🏫'),
    Topic(id: 'work', name: 'Work', emoji: '💼'),
    Topic(id: 'transportation', name: 'Transportation', emoji: '🚗'),
    Topic(id: 'flora', name: 'Plants', emoji: '🌿'),
    Topic(id: 'shopping_mall', name: 'Shopping Mall', emoji: '🛍️'),
  ];

  List<Topic> _topics = [];
  List<Topic> get topics => _topics;

  Future<void> _loadTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final topicsData = prefs.getString('topics');
      if (topicsData != null) {
        final List<dynamic> decoded = jsonDecode(topicsData) as List;
        _topics = decoded
            .map((json) => Topic.fromJson(json as Map<String, dynamic>))
            .toList();
        // Keep only supported IDs from defaults, then add any missing defaults
        final supported = _defaultTopics.map((t) => t.id).toSet();
        _topics = _topics.where((t) => supported.contains(t.id) || t.id.startsWith('quizlab_')).toList();
        for (final def in _defaultTopics) {
          if (!_topics.any((t) => t.id == def.id)) {
            _topics.add(Topic(id: def.id, name: def.name, emoji: def.emoji));
          }
        }
        _topics.sort((a, b) => a.name.compareTo(b.name));
        await _saveTopics();
      } else {
        _topics = List.from(_defaultTopics);
        _topics.sort((a, b) => a.name.compareTo(b.name));
        await _saveTopics();
      }
      await _addQuizLabCategories();
      notifyListeners();
    } catch (e) {
      _topics = List.from(_defaultTopics);
      debugPrint('Error loading topics: $e');
    }
  }

  Future<void> _addQuizLabCategories() async {
    try {
      final data = jsonDecode(await rootBundle.loadString(
        'assets/data/quizlab_terms.json')) as Map<String, dynamic>;
      final categories = <String, String>{};
      for (final raw in data['terms'] as List<dynamic>? ?? []) {
        if (raw is! Map<String, dynamic>) continue;
        final label = (raw['category'] ?? 'General').toString().trim();
        if (label.isEmpty) continue;
        categories[quizLabTopicId(label)] = label;
      }
      for (final entry in categories.entries) {
        if (_topics.any((t) => t.id == entry.key)) continue;
        _topics.add(Topic(id: entry.key, name: entry.value, emoji: '📚'));
      }
      _topics.sort((a, b) => a.name.compareTo(b.name));
      await _saveTopics();
    } catch (e) {
      debugPrint('Quiz Lab topic metadata unavailable: $e');
    }
  }

  Future<void> _saveTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'topics',
        jsonEncode(_topics.map((t) => t.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving topics: $e');
    }
  }

  Future<void> toggleTopic(String topicId) async {
    final index = _topics.indexWhere((t) => t.id == topicId);
    if (index != -1) {
      _topics[index].isSelected = !_topics[index].isSelected;
      await _saveTopics();
      notifyListeners();
    }
  }

  List<Topic> getSelectedTopics() =>
      _topics.where((t) => t.isSelected).toList();

  Future<void> clearSelection() async {
    for (var topic in _topics) {
      topic.isSelected = false;
    }
    await _saveTopics();
    notifyListeners();
  }

  List<Topic> getRecentTopics() =>
      _topics.where((t) => t.isSelected).take(3).toList();
}
