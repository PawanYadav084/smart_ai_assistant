import 'widgets/typing_indicator.dart';
import 'widgets/chat_bubble.dart';
import '../../../models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
import 'widgets/message_input.dart';
import 'widgets/image_preview.dart';
import 'widgets/pdf_preview.dart';
import '../../../core/services/chat_service.dart';
import '../../../models/pdf_document.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/services/pdf_service.dart';
import '../../settings/presentation/settings_screen.dart';






class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  PdfDocumentModel? _selectedPdf;

  final FilePicker _filePicker = FilePicker.platform;
  final PdfService _pdfService = PdfService();
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  late ChatService _chatService;

  bool _isListening = false;

  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  late AIService _aiService;
  final GeminiService _geminiVisionService = GeminiService();
  final MemoryService _memoryService = MemoryService();
  final ChatRepository _chatRepository = ChatRepository();
  final List<Content> _conversation = [];
  List<Conversation> _conversations = [];
  int? _currentConversationId;
  final ConversationRepository _conversationRepository =
      ConversationRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _filteredConversations = [];
  final Map<int, String> _conversationPreviews = {};

  // bool _isSearching = false;

bool _isTyping = false;
bool _webSearchEnabled = false;
String _typingMessage = '🤖 Thinking...';
bool _cancelGeneration = false;

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();

    switch (AppConfig.provider) {
      case AIProvider.gemini:
        _aiService = FallbackAIService();
        break;
      case AIProvider.groq:
        _aiService = GroqService();
        break;
    }

    _chatService = ChatService(
      aiService: _aiService,
      geminiVisionService: _geminiVisionService,
      memoryService: _memoryService,
      chatRepository: _chatRepository,
      conversationRepository: _conversationRepository,
    );

    _loadConversations();
    // _clearChatOnStartup(); // removed as per instructions
  }
  Future<void> _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _loadChatHistory() async {
    if (_currentConversationId == null) {
      if (!mounted) return;
      setState(() {
        _messages.clear();
        _conversation.clear();
      });
      return;
    }
    final chatHistory = await _chatRepository.getMessages(
      _currentConversationId!,
    );

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
              imagePath: history.imagePath,
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

  conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  _conversationPreviews.clear();

  for (final conversation in conversations) {
    final lastMessage =
        await _chatRepository.getLastMessage(conversation.id!);

    _conversationPreviews[conversation.id!] =
        lastMessage?.message ?? 'No messages yet';
  }

  if (!mounted) return;

  setState(() {
    _conversations = conversations;
    _filteredConversations = List.from(conversations);
  });
}


  Future<void> _sendMessage() async {
    if (_isTyping) return;
    _cancelGeneration = false;
    final typedMessage = _controller.text.trim();
    final selectedImage = _selectedImage;
    final selectedPdf = _selectedPdf;

    if (typedMessage.isEmpty &&
        selectedImage == null &&
        selectedPdf == null) {
      return;
    }

    final timestamp = DateTime.now();
    final userMessage = typedMessage.isEmpty
        ? (selectedPdf != null
            ? 'Summarize this PDF.'
            : selectedImage != null
                ? 'Analyze this image.'
                : '')
        : typedMessage;

    setState(() {
      _messages.add(
        ChatMessage(
          message: userMessage,
          isUser: true,
          time: timestamp,
          imagePath: selectedImage?.path,
        ),
      );

      _conversation.add(Content.text(userMessage));
      if (selectedPdf != null) {
        _typingMessage = '📄 Analyzing PDF...';
      } else if (_webSearchEnabled && typedMessage.isNotEmpty) {
        _typingMessage = '🌐 Searching the web...';
      } else if (selectedImage != null) {
        _typingMessage = '🖼️ Analyzing image...';
      } else {
        _typingMessage = '🤖 Thinking...';
      }
      _isTyping = true;
      _selectedImage = null;
      // _selectedPdf = null;  // removed as per instructions
    });

    _controller.clear();
    _scrollToBottom();

    try {
      if (_currentConversationId == null) {
        _currentConversationId =
            await _conversationRepository.createNewConversation();
      }
      await _chatService.saveUserMessage(
        conversationId: _currentConversationId!,
        message: userMessage,
        image: selectedImage,
      );

      await _loadConversations();

      final String reply;
      if (selectedPdf != null) {
        if (typedMessage.isEmpty) {
          reply = await _geminiVisionService.summarizePdf(
            selectedPdf.extractedText,
          );
        } else {
          reply = await _geminiVisionService.askPdf(
            pdfText: selectedPdf.extractedText,
            question: typedMessage,
          );
        }
      } else if (_webSearchEnabled && typedMessage.isNotEmpty) {
        reply = await _chatService.generateWebReply(
          query: typedMessage,
        );
      } else {
        reply = await _chatService.generateReply(
          conversation: _conversation,
          image: selectedImage,
          userMessage: userMessage,
        );
      }

      // Check for cancellation after reply is obtained, before adding message
      if (_cancelGeneration) {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
        });
        return;
      }

      final responseTime = DateTime.now();

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            message: reply,
            isUser: false,
            time: responseTime,
          ),
        );

        _conversation.add(Content.model([TextPart(reply)]));
        _isTyping = false;
      });

      await _chatService.saveAssistantMessage(
        conversationId: _currentConversationId!,
        message: reply,
      );

      if (selectedImage != null) {
        setState(() {
          _selectedImage = null;
        });
      }

      await _loadConversations();
      if (!mounted) return;
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            message: '⚠️ $e',
            isUser: false,
            time: DateTime.now(),
          ),
        );
        _isTyping = false;
        // Restore attachments so user can retry
        _selectedImage = selectedImage;
        _selectedPdf = selectedPdf;
      });
    }
  }
  void _stopGenerating() {
    if (!_isTyping) return;
    setState(() {
      _cancelGeneration = true;
      _isTyping = false;
    });
  }

  Future<void> _regenerateLastResponse() async {
    if (_isTyping || _messages.length < 2) return;

    // Remove last AI message if present.
    if (_messages.isNotEmpty && !_messages.last.isUser) {
      _messages.removeLast();
      if (_conversation.isNotEmpty) {
        _conversation.removeLast();
      }
    }

    // Find the last user message.
    final lastUser = _messages.lastWhere(
      (m) => m.isUser,
      orElse: () => ChatMessage(
        message: '',
        isUser: true,
        time: DateTime.now(),
      ),
    );

    if (lastUser.message.isEmpty) return;

    setState(() {
      _controller.text = lastUser.message;
    });

    await _sendMessage();
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
    // Delete current conversation only if it has no messages.
    if (_currentConversationId != null) {
      await _conversationRepository.deleteIfEmpty(_currentConversationId!);
    }

    if (!mounted) return;

    setState(() {
      _currentConversationId = null;
      _messages.clear();
      _conversation.clear();
      _conversations.clear();
      _filteredConversations.clear();
      _isTyping = false;
      _controller.clear();
      _selectedImage = null;
      _selectedPdf = null;
    });

    await _loadConversations();
  }

  Future<void> _deleteConversation(Conversation conversation) async {
    await _conversationRepository.deleteConversation(conversation.id!);

    if (!mounted) return;

    setState(() {
      _selectedPdf = null;
      _selectedImage = null;
    });

    await _loadConversations();

    if (_conversations.isNotEmpty && _conversations.first.id != null) {
      _currentConversationId = _conversations.first.id!;
      _messages.clear();
      _conversation.clear();
      await _loadChatHistory();
    } else {
      setState(() {
        _currentConversationId = null;
        _messages.clear();
        _conversation.clear();
        _selectedImage = null;
        _selectedPdf = null;
        _controller.clear();
        _isTyping = false;
      });
    }
  }

  Future<void> _renameConversation(Conversation conversation) async {
    final controller = TextEditingController(text: conversation.title);

    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title:  Text('Rename Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Conversation title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child:  Text('Save'),
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null || !mounted) return;

    setState(() {
      _selectedImage = File(image.path);
      _selectedPdf = null; // Clear PDF selection when an image is picked
    });
  }

  Future<void> _pickPdf() async {
    final result = await _filePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    if (picked.path == null) return;

    final file = File(picked.path!);
    final text = await _pdfService.extractText(file);

    // Stability improvement: Show message if no readable text found
    if (text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No readable text found in this PDF.'),
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _selectedPdf = PdfDocumentModel(
        file: file,
        fileName: picked.name,
        extractedText: text,
      );
      _selectedImage = null; // Clear image selection when a PDF is picked
    });
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
             Text(
              'Choose Image',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title:  Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title:  Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredConversations = List.from(_conversations);
      } else {
        _filteredConversations = _conversations.where((conversation) {
          return conversation.title.toLowerCase().contains(query.toLowerCase());
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

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        groups['Today']!.add(conversation);
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
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
        title:  Text('Start New Chat?'),
        content:  Text('This will clear your current conversation.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:  Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearChat();
            },
            child:  Text('New Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      drawer: Drawer(
        backgroundColor: colors.surface,
        child: SafeArea(
          child: Column(
            children: [
              DrawerHeader(
                child: Center(
                  child: Text(
                    'Smart AI Assistant',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_comment_outlined),
                title:  Text('New Chat'),
                onTap: () async {
                  Navigator.pop(context);
                  await _clearChat();
                },
              ),
              
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Recent Chats',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredConversations.isEmpty
                    ? Center(child: Text('No chat history yet.'))
                    : (() {
                        final grouped = _groupConversations();
                        final List<Widget> children = [];
                        grouped.entries.forEach((entry) {
                          children.add(
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  entry.key,
                                  style:  TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          );
                          for (final conversation in entry.value) {
                            children.add(
                              ListTile(
                                leading: const Icon(Icons.chat_bubble_outline),
                                selected:
                                    _currentConversationId == conversation.id,
                                selectedTileColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.08),
                                title: Text(
                                  conversation.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _conversationPreviews[conversation.id!] ??
                                      'No messages yet',
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
                                  if (_currentConversationId ==
                                      conversation.id) {
                                    Navigator.pop(context);
                                    return;
                                  }
                                  setState(() {
                                    _currentConversationId = conversation.id!;
                                    _messages.clear();
                                    _conversation.clear();
                                    _isTyping = false;
                                    _selectedPdf = null;
                                    _selectedImage = null;
                                  });
                                  Navigator.pop(context);
                                  await _loadChatHistory();
                                },
                                onLongPress: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title:  Text('Delete Conversation'),
                                      content:  Text(
                                        'Delete this conversation permanently?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child:  Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child:  Text('Delete'),
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
                        return ListView(children: children);
                      })(),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title:  Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        title:  Text("Smart AI Chat"),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: _webSearchEnabled ? 'Web Search ON' : 'Web Search OFF',
              icon: Icon(
              Icons.travel_explore,
              color: _webSearchEnabled 
              ? colors.primary
              : colors.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _webSearchEnabled = !_webSearchEnabled;
              });
            },
          ),
          if (_isTyping)
            IconButton(
              tooltip: 'Stop',
              // icon: const Icon(Icons.stop_circle_outlined),
              icon: Icon(
                Icons.stop,
                color: colors.error,
                size: 28,
              ),
              onPressed: _stopGenerating,
            ),
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
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 45,
                                  backgroundColor: colors.primary,
                                  child: Icon(
                                    Icons.smart_toy,
                                    color: colors.onPrimary,
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
                                    color: colors.onSurfaceVariant,
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
                                onRegenerate: chat.isUser ? null : _regenerateLastResponse,
                              );
                            },
                          ),
                  ),
                  if (_isTyping)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TypingIndicator(
                          message: _typingMessage,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            ImagePreview(
              image: _selectedImage,
              isUploading: _isTyping,
              onRemove: () {
                setState(() {
                  _selectedImage = null;
                });
              },
            ),

            PdfPreview(
              fileName: _selectedPdf?.fileName,
              isUploading: _isTyping,
              onRemove: () {
                setState(() {
                  _selectedPdf = null;
                });
              },
            ),

            SafeArea(
              top: false,
              child: MessageInput(
                controller: _controller,
                isTyping: _isTyping,
                isListening: _isListening,
                onSend: _sendMessage,
                onMicPressed: _toggleListening,
                onImagePressed: _showImagePickerSheet,
                onPdfPressed: _pickPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
