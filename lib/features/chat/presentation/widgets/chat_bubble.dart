import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage chat;

  const ChatBubble({
    super.key,
    required this.chat,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: chat.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!chat.isUser) ...[
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2575FC),
            child: Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
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
              //borderRadius: BorderRadius.circular(16),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(chat.isUser ? 20 : 4),
                bottomRight: Radius.circular(chat.isUser ? 4 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  chat.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text(
                //   chat.message,
                //   style: TextStyle(
                //     color: chat.isUser ? Colors.white : Colors.black,
                //     fontSize: 16,
                //   ),
                // ),
                MarkdownBody(
                  data: chat.message,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      color: chat.isUser ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
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
        ),
        if (chat.isUser) ...[
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2575FC),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ],
    );
  }
}