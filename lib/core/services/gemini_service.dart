// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';

// class GeminiService {
//   final GenerativeModel _model = GenerativeModel(
//     model: 'gemini-2.5-flash',
//     apiKey: dotenv.env['GEMINI_API_KEY']!,
//   );

//   Future<String> generateResponse(List<Content> conversation) async {
//     try {
//       final response = await _model
//           .generateContent(conversation)
//           .timeout(const Duration(seconds: 30));

//       return response.text ?? "Sorry, I couldn't generate a response.";
//   //   } on GenerativeAIException catch (e) {
//   //     print("Gemini Error:");
//   //     print(e.message);
//   //     return "Gemini Error:\n${e.message}";
    
//   //     final error = e.message;

//   //     if (error.contains('503') || error.contains('UNAVAILABLE')) {
//   //       return '⚠️ Gemini server is busy.\nPlease try again in a few seconds.';
//   //     }

//   //     if (error.contains('429') ||
//   //         error.toLowerCase().contains('quota') ||
//   //         error.toLowerCase().contains('rate limit')) {
//   //       return '⚠️ Request limit reached.\nPlease wait a few seconds and try again.';
        
//   //     }

//   //     return '⚠️ Unable to contact Gemini.\nPlease try again later.';
//   //   } catch (_) {
//   //     return '⚠️ Something went wrong.\nPlease check your internet connection.';
//   //   }
//   // }
//   // }


// } on GenerativeAIException catch (e) {
//   final error = e.message;

//   if (error.contains('429') ||
//       error.toLowerCase().contains('quota') ||
//       error.toLowerCase().contains('rate limit')) {
//     return '⚠️ Gemini Free Tier limit reached.\n'
//            'Please wait about one minute and try again.';
//   }

//   if (error.contains('503') ||
//       error.toLowerCase().contains('unavailable')) {
//     return '⚠️ Gemini server is busy.\n'
//            'Please try again later.';
//   }

//   return '⚠️ Gemini Error:\n$error';
// }



import 'ai_service.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService implements AIService {
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

  Future<String> generateImageResponse({
    required File image,
    required String prompt,
  }) async {
    try {
      final bytes = await image.readAsBytes();

      final response = await _model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', bytes),
        ]),
      ]).timeout(const Duration(seconds: 60));

      return response.text ?? 'Sorry, I could not analyze the image.';
    } on GenerativeAIException catch (e) {
      return '⚠️ Gemini Vision Error:\n${e.message}';
    } catch (_) {
      return '⚠️ Failed to analyze the image.';
    }
  }
}

