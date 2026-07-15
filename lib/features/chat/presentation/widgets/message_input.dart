import 'package:flutter/material.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isTyping;
  final bool isListening;

  final VoidCallback onSend;
  final VoidCallback onMicPressed;
  final VoidCallback onImagePressed;
  final VoidCallback onPdfPressed;
  const MessageInput({
    super.key,
    required this.controller,
    required this.isTyping,
    required this.isListening,
    required this.onSend,
    required this.onMicPressed,
    required this.onImagePressed,
    required this.onPdfPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
          icon: const Icon(Icons.picture_as_pdf_outlined),
          tooltip: 'Pick PDF',
          onPressed: onPdfPressed,
        ),

          IconButton(
          icon: const Icon(Icons.image_outlined),
          tooltip: 'Pick Image',
          onPressed: onImagePressed,
        ),

          CircleAvatar(
            radius: 24,
            child: IconButton(
              icon: Icon(
                isListening ? Icons.mic : Icons.mic_none,
              ),
              onPressed: onMicPressed,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isTyping,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              textCapitalization:
                  TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF2575FC),
            child: IconButton(
              onPressed: isTyping ? null : onSend,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}