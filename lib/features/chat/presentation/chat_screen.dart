import 'widgets/typing_indicator.dart';
import 'widgets/chat_bubble.dart';
import '../../../models/chat_message.dart';
import 'package:flutter/material.dart';
// import '../../../core/services/gemini_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/memory/memory_parser.dart';
import '../../../core/memory/memory_service.dart';
import '../../../database/chat_repository.dart';
import '../../../database/chat_history.dart';
import '../../../database/conversation.dart';
import '../../../database/conversation_repository.dart';
import '../../../core/services/groq_service.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/fallback_ai_service.dart';
import '../../../core/config/app_config.dart';




class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];

  late AIService _aiService;
  final MemoryService _memoryService = MemoryService();
  final ChatRepository _chatRepository = ChatRepository();
  final List<Content> _conversation = [];
  List<Conversation> _conversations = [];
  int _currentConversationId = 1;
  final ConversationRepository _conversationRepository = ConversationRepository();

  bool _isTyping = false;

  @override
  void initState() {
    super.initState();

    switch (AppConfig.provider) {
      case AIProvider.gemini:
        _aiService = FallbackAIService();
        break;

      case AIProvider.groq:
        _aiService = GroqService();
        break;
    }

    _loadChatHistory();
    _loadConversations();
  }

  Future<void> _loadChatHistory() async {
    final chatHistory = await _chatRepository.getMessages(_currentConversationId);

    if (!mounted) return;

    setState(() {
      chatHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (_messages.isEmpty) {
        _messages.clear();
        _conversation.clear();

        for (final history in chatHistory) {
          _messages.add(
            ChatMessage(
              message: history.message,
              isUser: history.isUser,
              time: history.timestamp,
            ),
          );

          _conversation.add(
            history.isUser
              ? Content.text(history.message)
              : Content.model([TextPart(history.message)]),
          );
        }
      }
    });

    _scrollToBottom();
  }

  Future<void> _loadConversations() async {
    final conversations = await _conversationRepository.getAllConversations();
    if (!mounted) return;
    setState(() {
      _conversations = conversations;
    });
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (_isTyping) return;
    if (message.isEmpty) return;
    final memory = MemoryParser.extractMemory(message);

    if (memory.isNotEmpty) {
      await _memoryService.saveMemory(memory);
    }

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
    });
    try {
      await _chatRepository.saveMessage(
        ChatHistory(
          conversationId: _currentConversationId,
          message: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      await _conversationRepository.updateTitleIfNeeded(
        _currentConversationId,
        message,
      );

      await _conversationRepository.updateConversation(
        _currentConversationId,
      );

      await _loadConversations();
    } catch (e) {
      debugPrint('Failed to save user message: $e');
    }
    _scrollToBottom();

    _controller.clear();

    try {
      final savedMemory = await _memoryService.loadMemory();

      final memoryPrompt = '''
      User Information:
      Name: ${savedMemory['name']}
      City: ${savedMemory['city']}
      Profession: ${savedMemory['profession']}
      Favorite Language: ${savedMemory['language']}

      Use this information only if it is relevant to the user's request.
      ''';
      final requestConversation = [
        Content.text(memoryPrompt),
        ..._conversation,
      ];
      final reply = await _aiService.generateResponse(requestConversation);

      if (!mounted) return;

      // Streaming effect for AI response
      _messages.add(
        ChatMessage(
          message: '',
          isUser: false,
          time: DateTime.now(),
        ),
      );

      final words = reply.split(' ');

      for (int i = 0; i < words.length; i++) {
        if (!mounted) return;

        await Future.delayed(const Duration(milliseconds: 35));

        setState(() {
          final current = _messages.last;

          _messages[_messages.length - 1] = ChatMessage(
            message: current.message.isEmpty
                ? words[i]
                : '${current.message} ${words[i]}',
            isUser: false,
            time: current.time,
          );
        });

        _scrollToBottom();
      }

      try {
        await _chatRepository.saveMessage(
          ChatHistory(
            conversationId: _currentConversationId,
            message: reply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        await _conversationRepository.updateConversation(
          _currentConversationId,
        );
        await _loadConversations();
      } catch (e) {
        debugPrint('Failed to save AI message: $e');
      }
      _conversation.add(Content.model([TextPart(reply)]));

      setState(() {
        _isTyping = false;
      });
    } catch (e, stackTrace) {
      debugPrint("ERROR: $e");
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            message: '⚠️ AI service is temporarily unavailable.',
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

  Future<void> _clearChat() async {
    final newConversationId = await _conversationRepository.createNewConversation();

    if (!mounted) return;

    setState(() {
      _currentConversationId = newConversationId;
      _messages.clear();
      _conversation.clear();
      _conversations = [];
      _isTyping = false;
      _controller.clear();
    });
    await _loadConversations();
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Chat?'),
        content: const Text('This will clear your current conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChat();
            },
            child: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const DrawerHeader(
                child: Center(
                  child: Text(
                    'Smart AI Assistant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_comment_outlined),
                title: const Text('New Chat'),
                onTap: () async {
                  Navigator.pop(context);
                  await _clearChat();
                },
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: const Text('Search Chats'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent Chats',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _conversations.isEmpty
                    ? const Center(
                        child: Text('No chat history yet.'),
                      )
                    : ListView.builder(
                        itemCount: _conversations.length,
                        itemBuilder: (context, index) {
                          final conversation = _conversations[index];
                          return ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: Text(conversation.title),
                            subtitle: Text(
                              '${conversation.updatedAt.day}/${conversation.updatedAt.month}/${conversation.updatedAt.year}',
                            ),
                            onTap: () async {
                              _currentConversationId = conversation.id!;
                              Navigator.pop(context);
                              await _loadChatHistory();
                            },
                          );
                        },
                      ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text("Smart AI Chat"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showClearChatDialog,
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
                      enabled: !_isTyping,
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
                      onPressed: _isTyping ? null : _sendMessage,
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}