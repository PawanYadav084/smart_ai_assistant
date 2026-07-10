import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  Future<String> generateResponse(List<Content> conversation) async {
    try {
      final response = await _model.generateContent(conversation);

      return response.text ?? "Sorry, I couldn't generate a response.";
    } on GenerativeAIException catch (e) {
      if (e.message.contains('503') || e.message.contains('UNAVAILABLE')) {
        return '⚠️ Gemini server is busy right now. Please try again in a few seconds.';
      }
      return '⚠️ Gemini API Error: ${e.message}';
    } catch (_) {
      return '⚠️ Something went wrong. Please check your internet connection and API key, then try again.';
    }
  }
}