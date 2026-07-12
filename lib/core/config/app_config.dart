enum AIProvider {
  gemini,
  groq,
}

class AppConfig {
  static const AIProvider provider = AIProvider.groq;
}