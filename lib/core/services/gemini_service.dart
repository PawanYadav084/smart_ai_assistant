import 'ai_service.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService implements AIService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.5-flash',
    apiKey: dotenv.env['GEMINI_API_KEY']!,
  );

  @override
  Future<String> generateResponse(List<Content> conversation) async {
    try {
      final response = await _model
          .generateContent(conversation)
          .timeout(const Duration(seconds: 30));

      return response.text ?? "Sorry, I couldn't generate a response.";
    } on GenerativeAIException catch (e) {
      final error = e.message;

      if (error.contains('429') ||
          error.toLowerCase().contains('quota') ||
          error.toLowerCase().contains('rate limit')) {
        return '⚠️ Gemini Free Tier limit reached.\n'
            'Please wait about one minute and try again.';
      }

      if (error.contains('503') ||
          error.toLowerCase().contains('unavailable')) {
        return '⚠️ Gemini server is busy.\n'
            'Please try again later.';
      }

      return '⚠️ Gemini Error:\n$error';
    } catch (_) {
      return '⚠️ Something went wrong.\nPlease check your internet connection.';
    }
  }

  @override
  Future<String> generateWebResponse({
    required String query,
  }) async {
    return generateResponse([
      Content.text(query),
    ]);
  }

  Future<String> generateImageResponse({
    required File image,
    required String prompt,
  }) async {
    try {
      final bytes = await image.readAsBytes();

      final response = await _model
          .generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart(_imageMimeType(image), bytes),
            ]),
          ])
          .timeout(const Duration(seconds: 60));

      return response.text ?? 'Sorry, I could not analyze the image.';
    } on GenerativeAIException catch (e) {
      return '⚠️ Gemini Vision Error:\n${e.message}';
    } catch (_) {
      return '⚠️ Failed to analyze the image.';
    }
  }

  Future<String> summarizePdf(String pdfText) async {
    final prompt = '''
You are an AI assistant.

Summarize the following PDF in clear sections:
- Overview
- Key Points
- Important Facts
- Conclusion

PDF CONTENT:
$pdfText
''';

    return generateResponse([
      Content.text(prompt),
    ]);
  }

  Future<String> askPdf({
    required String pdfText,
    required String question,
  }) async {
    final prompt = '''
You are answering questions using only the provided PDF.

PDF CONTENT:
$pdfText

QUESTION:
$question

If the answer is not available in the PDF, clearly state that it is not present.
''';

    return generateResponse([
      Content.text(prompt),
    ]);
  }

  String _imageMimeType(File image) {
    final path = image.path.toLowerCase();

    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic') || path.endsWith('.heif')) {
      return 'image/heic';
    }

    return 'image/jpeg';
  }
}
