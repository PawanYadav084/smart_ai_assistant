import 'widgets/typing_indicator.dart';
import 'widgets/chat_bubble.dart';
import '../../../models/chat_message.dart';
import 'package:flutter/material.dart';
import '../../../core/services/gemini_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  final GeminiService _geminiService = GeminiService();
  final List<Content> _conversation = [];

  bool _isTyping = false;

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          message: message,
          isUser: true,
          time: DateTime.now(),
        ),
      );
      _conversation.add(Content.text(message));
      _isTyping = true;
      _scrollToBottom();
    });

    _controller.clear();

    try {
      final reply = await _geminiService.generateResponse(_conversation);

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            message: reply,
            isUser: false,
            time: DateTime.now(),
          ),
        );
        _conversation.add(
          Content.model([
            TextPart(reply),
          ]),
        );

        _isTyping = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            message: 'Error: Unable to get AI response.',
            isUser: false,
            time: DateTime.now(),
          ),
        );

        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _conversation.clear();
      _isTyping = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart AI Chat"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_outline),
            tooltip: "New Chat",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Chat Area
            Expanded(
              child: Column(
  children: [
    Expanded(
      child: _messages.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFF2575FC),
                    child: Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 45,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Hello Pawan 👋",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "How can I help you today?",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final chat = _messages[index];

                return ChatBubble(chat: chat);
              },
            ),
          ),
                  if (_isTyping)
                    const Padding(
                      padding: EdgeInsets.only(
                      left: 16,
                      bottom: 12,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TypingIndicator(),
                    ),
                  ),
                ],
              ),
            ),

            // Message Box
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [

                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
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
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}