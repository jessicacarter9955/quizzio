class Topic {
  final String id;
  final String name;
  final String emoji;
  bool isSelected;

  Topic({
    required this.id,
    required this.name,
    required this.emoji,
    this.isSelected = false,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'emoji': emoji, 'isSelected': isSelected};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Topic && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Topic($id, $name, $emoji)';
}
