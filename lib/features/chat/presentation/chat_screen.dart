import 'widgets/typing_indicator.dart';
import 'widgets/chat_bubble.dart';
import '../../../models/chat_message.dart';
import 'package:flutter/material.dart';
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
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/gemini_service.dart';




class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;

  bool _isListening = false;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  late AIService _aiService;
  final MemoryService _memoryService = MemoryService();
  final ChatRepository _chatRepository = ChatRepository();
  final List<Content> _conversation = [];
  List<Conversation> _conversations = [];
  int _currentConversationId = 1;
  final ConversationRepository _conversationRepository = ConversationRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _filteredConversations = [];
  final Map<int, String> _conversationPreviews = {};

  // bool _isSearching = false;

  bool _isTyping = false;

  @override
  void initState() {
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();

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

  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadChatHistory() async {
    final chatHistory = await _chatRepository.getMessages(_currentConversationId);

    if (!mounted) return;

    setState(() {
      chatHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // if (_messages.isEmpty) 
      {
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
      conversations.sort(
        (a, b) => b.updatedAt.compareTo(a.updatedAt),
      );
      _conversations = conversations;
      _filteredConversations = List.from(conversations);
    });
    for (final conversation in conversations) {
      final lastMessage = await _chatRepository.getLastMessage(conversation.id!);
      _conversationPreviews[conversation.id!] =
          lastMessage?.message ?? 'No messages yet';
    }
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (_isTyping) return;
    if (message.isEmpty && _selectedImage == null) return;
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
      // final reply = await _aiService.generateResponse(requestConversation);
      String reply;

      if (_selectedImage != null && _aiService is GeminiService) {
      reply = await (_aiService as GeminiService).generateImageResponse(
      image: _selectedImage!,
      prompt: message.isEmpty
        ? 'Describe this image in detail.'
        : message,
  );
} else {
  reply = await _aiService.generateResponse(requestConversation);
}

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

  // Future<void> _clearChat() async {
  //   final newConversationId = await _conversationRepository.createNewConversation();

  //   if (!mounted) return;

  //   setState(() {
  //     _currentConversationId = newConversationId;
  //     _messages.clear();
  //     _conversation.clear();
  //     _conversations = [];
  //     _isTyping = false;
  //     _controller.clear();
  //   });
  //   await _loadConversations();
  // }

  Future<void> _clearChat() async {
  // Delete current conversation only if it has no messages.
  await _conversationRepository.deleteIfEmpty(_currentConversationId);

  final newConversationId =
      await _conversationRepository.createNewConversation();

  if (!mounted) return;

  setState(() {
    _currentConversationId = newConversationId;
    _messages.clear();
    _conversation.clear();
    _conversations.clear();
    _filteredConversations.clear();
    _isTyping = false;
    // _controller.clear();
    _selectedImage = null;
  });

  await _loadConversations();
}

  Future<void> _deleteConversation(Conversation conversation) async {
    await _conversationRepository.deleteConversation(conversation.id!);

    if (!mounted) return;

    await _loadConversations();

    if (_conversations.isNotEmpty) {
      _currentConversationId = _conversations.first.id!;
      _messages.clear();
      _conversation.clear();
      await _loadChatHistory();
    } else {
      await _clearChat();
    }
  }

  Future<void> _renameConversation(Conversation conversation) async {
    final controller = TextEditingController(text: conversation.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Conversation title',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newTitle == null || newTitle.isEmpty) return;

    await _conversationRepository.renameConversation(
      conversation.id!,
      newTitle,
    );

    await _loadConversations();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
      debugPrint('Speech available: $available');
      if (!available) return;
      setState(() => _isListening = true);
      await _speech.listen(
        localeId: 'en_US',
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 5),
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
          });

          if (result.finalResult) {
            setState(() => _isListening = false);
          }
        },
      );
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() {
      _selectedImage = File(image.path);
    });
  }
  void _filterConversations(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredConversations = List.from(_conversations);
      } else {
        _filteredConversations = _conversations.where((conversation) {
          return conversation.title
              .toLowerCase()
              .contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Group conversations by date buckets: Today, Yesterday, Last 7 Days, Older
  Map<String, List<Conversation>> _groupConversations() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 7));

    final groups = <String, List<Conversation>>{
      'Today': [],
      'Yesterday': [],
      'Last 7 Days': [],
      'Older': [],
    };

    for (final conversation in _filteredConversations) {
      final date = conversation.updatedAt;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        groups['Today']!.add(conversation);
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        groups['Yesterday']!.add(conversation);
      } else if (date.isAfter(lastWeek)) {
        groups['Last 7 Days']!.add(conversation);
      } else {
        groups['Older']!.add(conversation);
      }
    }

    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
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
              // TextField(
              //   controller: _searchController,
              //   decoration: const InputDecoration(
              //     labelText: 'Search Chats',
              //     prefixIcon: Icon(Icons.search),
              //   ),
              //   onChanged: (value) {
              //     _filterConversations(value);

              //     suffixIcon: _searchController.text.isEmpty
              //       ? null
              //       : IconButton(
              //         icon: const Icon(Icons.clear),
              //         onPressed: () {
              //           _searchController.clear();
              //           _filterConversations('');
              //         },
              //       ),
              //    },
              //  ),
              TextField(
  controller: _searchController,
  decoration: InputDecoration(
    labelText: 'Search Chats',
    prefixIcon: const Icon(Icons.search),
    suffixIcon: _searchController.text.isEmpty
        ? null
        : IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _filterConversations('');
              setState(() {});
            },
          ),
  ),
  onChanged: (value) {
    setState(() {});
    _filterConversations(value);
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
                child: _filteredConversations.isEmpty
                    ? const Center(
                        child: Text('No chat history yet.'),
                      )
                    : (() {
                        final grouped = _groupConversations();
                        final List<Widget> children = [];
                        grouped.entries.forEach((entry) {
                          children.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                          for (final conversation in entry.value) {
                            children.add(
                              ListTile(
                                leading: const Icon(Icons.chat_bubble_outline),
                                selected: _currentConversationId == conversation.id,
                                selectedTileColor:
                                    Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                title: Text(
                                  conversation.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _conversationPreviews[conversation.id!] ?? 'No messages yet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'rename') {
                                      await _renameConversation(conversation);
                                    } else if (value == 'delete') {
                                      await _deleteConversation(conversation);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'rename',
                                      child: Text('Rename'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  if (_currentConversationId == conversation.id) {
                                    Navigator.pop(context);
                                    return;
                                  }
                                  setState(() {
                                    _currentConversationId = conversation.id!;
                                    _messages.clear();
                                    _conversation.clear();
                                    _isTyping = false;
                                  });
                                  Navigator.pop(context);
                                  await _loadChatHistory();
                                },
                                onLongPress: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Delete Conversation'),
                                      content: const Text('Delete this conversation permanently?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (shouldDelete == true) {
                                    await _deleteConversation(conversation);
                                  }
                                },
                              ),
                            );
                          }
                        });
                        return ListView(
                          children: children,
                        );
                      })(),
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

                              return ChatBubble(
                                chat: chat,
                                onSpeak: chat.isUser
                                    ? null
                                    : () => _speak(chat.message),
                              );
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

            // Image preview (Gemini Vision UI - Stage 1)
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Message Box
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Pick Image',
                    onPressed: _pickImage,
                  ),
                  CircleAvatar(
                    radius: 24,
                    child: IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _toggleListening,
                    ),
                  ),
                  const SizedBox(width: 8),
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

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
// }

@override
void dispose() {
  _speech.stop();
  _flutterTts.stop();
  _searchController.dispose();
  _controller.dispose();
  _scrollController.dispose();
  super.dispose();
}
}