class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.time,
  });
}