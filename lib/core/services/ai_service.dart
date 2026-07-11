import 'package:google_generative_ai/google_generative_ai.dart';

abstract class AIService {
  Future<String> generateResponse(
    List<Content> conversation,
  );
}