class ChatHistory {
  final int? id;
  final int conversationId;
  final String message;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  const ChatHistory({
    this.id,
    required this.conversationId,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'image_path': imagePath,
    };
  }

  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    return ChatHistory(
      id: map['id'] as int?,
      conversationId: map['conversation_id'] as int,
      message: map['message'] as String,
      isUser: map['isUser'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      imagePath: map['image_path'] as String?,
    );
  }
}
