import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'ai_service.dart';

class GroqService implements AIService {
  final String _apiKey = dotenv.env['GROQ_API_KEY']!.trim();

  @override
  Future<String> generateResponse(List<Content> conversation) async {
    try {
      final List<Map<String, String>> messages = [];

      for (final content in conversation) {
        final role = content.role == 'model' ? 'assistant' : 'user';

        for (final part in content.parts) {
          if (part is TextPart) {
            messages.add({
              'role': role,
              'content': part.text,
            });
          }
        }
      }

      if (_apiKey.isEmpty) {
        return '⚠️ GROQ_API_KEY is missing.';
      }

      final response = await http.post(
        Uri.parse(
          'https://api.groq.com/openai/v1/chat/completions',
        ),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 2048,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return data['choices'][0]['message']['content'] as String;
      }

      if (response.statusCode == 429) {
        return '⚠️ Groq rate limit reached.\nPlease try again in a few seconds.';
      }

      if (response.statusCode == 401) {
        return '⚠️ Invalid Groq API Key.';
      }

      return '⚠️ Groq Error (${response.statusCode})\n${response.body}';
   }  catch (e, stackTrace) {
      debugPrint("========== GROQ ERROR ==========");
      debugPrint(e.toString());
      debugPrintStack(stackTrace: stackTrace);

      return "Groq Error:\n$e";
}
  }
}