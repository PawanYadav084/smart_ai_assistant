import 'dart:io';

import 'dart:math';

import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  static const int maxCharacters = 30000;
  Future<String> extractText(File file) async {
    try {
      final bytes = await file.readAsBytes();

      final document = PdfDocument(inputBytes: bytes);

      String text = PdfTextExtractor(document).extractText();

      document.dispose();

      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (text.length > maxCharacters) {
        text = text.substring(0, min(text.length, maxCharacters));
      }

      return text.trim();
    } catch (e) {
      throw Exception('Failed to extract PDF text: $e');
    }
  }
}