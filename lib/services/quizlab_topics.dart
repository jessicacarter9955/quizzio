/// Stable Wordweaver topic IDs for the original Quiz Lab categories.
/// Keeping this mapping shared avoids mismatched topics between Home and Quiz.
String quizLabTopicId(String category) {
  final slug = category.toLowerCase().trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return 'quizlab_${slug.isEmpty ? 'general' : slug}';
}
