import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  Future<String> generateResponse(List<Content> conversation) async {
    try {
      final response = await _model
          .generateContent(conversation)
          .timeout(const Duration(seconds: 30));

      return response.text ?? "Sorry, I couldn't generate a response.";
    } on GenerativeAIException catch (e) {
      final error = e.message;

      if (error.contains('503') || error.contains('UNAVAILABLE')) {
        return '⚠️ Gemini server is busy.\nPlease try again in a few seconds.';
      }

      if (error.contains('429') ||
          error.toLowerCase().contains('quota') ||
          error.toLowerCase().contains('rate limit')) {
        return '⚠️ Request limit reached.\nPlease wait a few seconds and try again.';
        
      }

      return '⚠️ Unable to contact Gemini.\nPlease try again later.';
    } catch (_) {
      return '⚠️ Something went wrong.\nPlease check your internet connection.';
    }
  }
}
