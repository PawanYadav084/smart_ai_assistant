import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'markdown_message.dart';
import '../../../../models/chat_message.dart';

class ChatBubble extends StatefulWidget {
  final ChatMessage chat;
  final VoidCallback? onSpeak;
  final VoidCallback? onRegenerate;

  const ChatBubble({
    super.key,
    required this.chat,
    this.onSpeak,
    this.onRegenerate,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _liked = false;
  bool _disliked = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: widget.chat.isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!widget.chat.isUser) ...[
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2575FC),
            child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.chat.isUser
                  ? const Color(0xFF2575FC)
                  : Colors.grey.shade300,
              //borderRadius: BorderRadius.circular(16),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(widget.chat.isUser ? 20 : 4),
                bottomRight: Radius.circular(widget.chat.isUser ? 4 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: widget.chat.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.chat.imagePath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.chat.imagePath!),
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                // Text(
                //   widget.chat.message,
                //   style: TextStyle(
                //     color: widget.chat.isUser ? Colors.white : Colors.black,
                //     fontSize: 16,
                //   ),
                // ),
                MarkdownMessage(
                  text: widget.chat.message,
                  textColor: widget.chat.isUser ? Colors.white : Colors.black,
                ),
                if (!widget.chat.isUser && widget.onSpeak != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.volume_up, size: 20),
                      tooltip: 'Read aloud',
                      onPressed: widget.onSpeak,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, size: 20),
                          tooltip: 'Copy message',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.chat.message),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Regenerate',
                          onPressed: widget.onRegenerate,
                        ),
                        IconButton(
                          icon: Icon(
                            _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 20,
                            color: _liked ? Colors.blue : null,
                          ),
                          tooltip: 'Like',
                          onPressed: () {
                            setState(() {
                              _liked = !_liked;
                              if (_liked) {
                                _disliked = false;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _disliked
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            size: 20,
                            color: _disliked ? Colors.blue : null,
                          ),
                          tooltip: 'Dislike',
                          onPressed: () {
                            setState(() {
                              _disliked = !_disliked;
                              if (_disliked) {
                                _liked = false;
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  "${widget.chat.time.hour}:${widget.chat.time.minute.toString().padLeft(2, '0')}",
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.chat.isUser ? Colors.white70 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.chat.isUser) ...[
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF2575FC),
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ],
    );
  }
}
