import 'dart:io';

class PdfDocumentModel {
  final File file;
  final String fileName;
  final String extractedText;

  const PdfDocumentModel({
    required this.file,
    required this.fileName,
    required this.extractedText,
  });
}