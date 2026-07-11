

class MemoryParser {
  static Map<String, String> extractMemory(String message) {
    final text = message.trim();
    final lower = text.toLowerCase();

    final Map<String, String> memory = {};

    if (lower.startsWith('my name is ')) {
      memory['name'] = text.substring(11).trim();
    }

    if (lower.startsWith("i live in ")) {
      memory['city'] = text.substring(10).trim();
    }

    if (lower.startsWith("i am a ")) {
      memory['profession'] = text.substring(7).trim();
    }

    if (lower.startsWith("my favourite language is ") ||
        lower.startsWith("my favorite language is ")) {
      final index = lower.contains('favourite') ? 25 : 24;
      memory['language'] = text.substring(index).trim();
    }

    return memory;
  }
}