import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _messages = [];

  void _sendMessage() {
    final message = _controller.text.trim();

    if (message.isEmpty) return;

    setState(() {
      _messages.add(message);
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart AI Chat"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Chat Area
            Expanded(
              child: Center(
                child: _messages.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2575FC),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                _messages[index],
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
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
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
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