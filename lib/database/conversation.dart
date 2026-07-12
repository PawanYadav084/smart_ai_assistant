

class Conversation {
  final int? id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as int?,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}