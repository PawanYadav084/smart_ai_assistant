import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../database/chat_history.dart';
import '../../database/chat_repository.dart';
import '../../database/conversation_repository.dart';
import '../memory/memory_parser.dart';
import '../memory/memory_service.dart';
import 'ai_service.dart';
import 'gemini_service.dart';
import 'tavily_service.dart';

class ChatService {
  ChatService({
    required AIService aiService,
    required GeminiService geminiVisionService,
    required MemoryService memoryService,
    required ChatRepository chatRepository,
    required ConversationRepository conversationRepository,
  })  : _aiService = aiService,
        _geminiVisionService = geminiVisionService,
        _memoryService = memoryService,
        _chatRepository = chatRepository,
        _conversationRepository = conversationRepository;

  final AIService _aiService;
  final GeminiService _geminiVisionService;
  final MemoryService _memoryService;
  final ChatRepository _chatRepository;
  final ConversationRepository _conversationRepository;
  final TavilyService _tavilyService = TavilyService();

  Future<String> buildMemoryPrompt() async {
    final savedMemory = await _memoryService.loadMemory();

    return '''
User Information:
Name: ${savedMemory['name']}
City: ${savedMemory['city']}
Profession: ${savedMemory['profession']}
Favorite Language: ${savedMemory['language']}

Use this information only if it is relevant to the user's request.
''';
  }

  Future<void> saveUserMessage({
    required int conversationId,
    required String message,
    File? image,
  }) async {
    final memory = MemoryParser.extractMemory(message);

    if (memory.isNotEmpty) {
      await _memoryService.saveMemory(memory);
    }

    await _chatRepository.saveMessage(
      ChatHistory(
        conversationId: conversationId,
        message: message,
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: image?.path,
      ),
    );

    await _conversationRepository.updateTitleIfNeeded(
      conversationId,
      message,
    );

    await _conversationRepository.updateConversation(
      conversationId,
    );
  }

  Future<String> generateReply({
    required List<Content> conversation,
    File? image,
    required String userMessage,
  }) async {
    final memoryPrompt = await buildMemoryPrompt();

    if (image != null) {
      return _geminiVisionService.generateImageResponse(
        image: image,
        prompt: '''
$memoryPrompt

The user attached an image. Analyze it carefully and answer this request:

$userMessage
''',
      );
    }

    final requestConversation = <Content>[
      Content.text(memoryPrompt),
      ...conversation,
    ];

    return _aiService.generateResponse(requestConversation);
  }

  Future<String> generatePdfReply({
    required String pdfText,
    required String userMessage,
  }) async {
    final memoryPrompt = await buildMemoryPrompt();

    final prompt = '''
$memoryPrompt

You are analyzing a PDF document.

PDF CONTENT:
$pdfText

USER REQUEST:
$userMessage

Answer using only the information from the PDF when possible. If the answer is not present in the PDF, clearly say so.
''';

    return _aiService.generateResponse([
      Content.text(prompt),
    ]);
  }

  Future<String> generateWebReply({
    required String query,
  }) async {
    final memoryPrompt = await buildMemoryPrompt();

    final searchResult = await _tavilyService.search(query);

    final prompt = '''
$memoryPrompt

Use the web search results below to answer the user's question.

QUESTION:
$query

WEB SEARCH RESULTS:
$searchResult

Provide a clear answer and include the important sources if relevant.
''';

    return _aiService.generateResponse([
      Content.text(prompt),
    ]);
  }

  Future<void> saveAssistantMessage({
    required int conversationId,
    required String message,
  }) async {
    await _chatRepository.saveMessage(
      ChatHistory(
        conversationId: conversationId,
        message: message,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    await _conversationRepository.updateConversation(
      conversationId,
    );
  }
}