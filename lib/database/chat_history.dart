

class ChatHistory {
  final int? id;
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatHistory({
    this.id,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    return ChatHistory(
      id: map['id'] as int?,
      message: map['message'] as String,
      isUser: map['isUser'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}