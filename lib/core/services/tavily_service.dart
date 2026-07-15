

import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TavilyService {
  TavilyService();

  final String _apiKey = dotenv.env['TAVILY_API_KEY']?.trim() ?? '';

  Future<String> search(String query) async {
    if (_apiKey.isEmpty) {
      throw Exception('TAVILY_API_KEY is missing in .env');
    }

    final response = await http.post(
      Uri.parse('https://api.tavily.com/search'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'api_key': _apiKey,
        'query': query,
        'search_depth': 'advanced',
        'max_results': 5,
        'include_answer': true,
        'include_raw_content': false,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Tavily API Error: ${response.body}');
    }

    final data = jsonDecode(response.body);

    final answer = data['answer'] ?? '';
    final results = (data['results'] as List?) ?? [];

    final buffer = StringBuffer();

    if (answer.toString().isNotEmpty) {
      buffer.writeln(answer);
      buffer.writeln();
    }

    if (results.isNotEmpty) {
      buffer.writeln('Sources:');
      for (final item in results) {
        buffer.writeln('- ${item['title']}');
        buffer.writeln('  ${item['url']}');
      }
    }

    return buffer.toString().trim();
  }
}