import 'package:google_generative_ai/google_generative_ai.dart';

abstract class AIService {
  Future<String> generateResponse(
    List<Content> conversation,
  );
  Future<String> generateWebResponse({
    required String query,
  }) async {
    throw UnimplementedError(
      'Web search is not implemented for this AI service.',
    );
  }
}