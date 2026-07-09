import 'package:flutter/material.dart';
import '../../../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage chat;

  const ChatBubble({
    super.key,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          chat.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: chat.isUser
              ? const Color(0xFF2575FC)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              chat.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chat.message,
              style: TextStyle(
                color: chat.isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${chat.time.hour}:${chat.time.minute.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontSize: 11,
                color: chat.isUser ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}