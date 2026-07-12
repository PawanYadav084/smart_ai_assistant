

import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_service.dart';
import 'gemini_service.dart';
import 'groq_service.dart';

class FallbackAIService implements AIService {
  final GeminiService _gemini = GeminiService();
  final GroqService _groq = GroqService();

  @override
  Future<String> generateResponse(List<Content> conversation) async {
    final geminiReply = await _gemini.generateResponse(conversation);

    final lower = geminiReply.toLowerCase();

    final shouldFallback =
        lower.contains('quota') ||
        lower.contains('rate limit') ||
        lower.contains('429') ||
        lower.contains('server is busy') ||
        lower.contains('503') ||
        lower.contains('resource exhausted');

    if (!shouldFallback) {
      return geminiReply;
    }

    return await _groq.generateResponse(conversation);
  }
}