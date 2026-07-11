

import 'package:shared_preferences/shared_preferences.dart';

class MemoryService {
  static const _nameKey = 'memory_name';
  static const _cityKey = 'memory_city';
  static const _professionKey = 'memory_profession';
  static const _languageKey = 'memory_language';

  Future<void> saveMemory(Map<String, String> memory) async {
    final prefs = await SharedPreferences.getInstance();

    if (memory.containsKey('name')) {
      await prefs.setString(_nameKey, memory['name']!);
    }

    if (memory.containsKey('city')) {
      await prefs.setString(_cityKey, memory['city']!);
    }

    if (memory.containsKey('profession')) {
      await prefs.setString(_professionKey, memory['profession']!);
    }

    if (memory.containsKey('language')) {
      await prefs.setString(_languageKey, memory['language']!);
    }
  }

  Future<Map<String, String>> loadMemory() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'name': prefs.getString(_nameKey) ?? '',
      'city': prefs.getString(_cityKey) ?? '',
      'profession': prefs.getString(_professionKey) ?? '',
      'language': prefs.getString(_languageKey) ?? '',
    };
  }

  Future<void> clearMemory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_cityKey);
    await prefs.remove(_professionKey);
    await prefs.remove(_languageKey);
  }
}