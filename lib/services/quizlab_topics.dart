/// Shared canonical taxonomy: Quiz Lab categories map to existing Wordweaver
/// topics when they mean the same thing, avoiding duplicate empty selections.
String quizLabTopicId(String category) {
  final slug = category.toLowerCase().trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  const aliases = <String, String>{
    'food': 'food',
    'food_drink': 'food',
    'food_and_drinks': 'food',
    'food_and_drink': 'food',
    'body': 'body',
    'body_parts': 'body',
    'family': 'family_and_relationships',
    'family_relationships': 'family_and_relationships',
    'family_and_relationships': 'family_and_relationships',
    'health': 'health',
    'home': 'home_and_rooms',
    'house': 'home_and_rooms',
    'home_and_rooms': 'home_and_rooms',
    'services': 'services',
    'countries': 'countries',
    'measurements': 'unit_of_measurement',
    'unit_of_measurement': 'unit_of_measurement',
    'animals': 'fauna',
    'fauna': 'fauna',
    'emotions': 'emotions_and_senses',
    'emotions_and_senses': 'emotions_and_senses',
    'sports': 'sports',
    'sport': 'sports',
    'hobbies': 'hobbies',
    'hobbies_and_leisure': 'hobbies',
    'school': 'school',
    'work': 'work',
    'jobs': 'work',
    'transport': 'transportation',
    'transportation': 'transportation',
    'plants': 'flora',
    'flora': 'flora',
    'shopping': 'shopping_mall',
    'shopping_mall': 'shopping_mall',
    'conversation': 'conversation',
    'conversations': 'conversation',
    'general_conversation': 'conversation',
  };
  return aliases[slug] ?? 'quizlab_${slug.isEmpty ? 'general' : slug}';
}
