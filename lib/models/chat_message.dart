class ChatMessage {
  final String message;
  final bool isUser;
  final DateTime time;
  final String? imagePath;

  ChatMessage({
    required this.message,
    required this.isUser,
    required this.time,
    this.imagePath,
  });
}
