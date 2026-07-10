import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'code_block.dart';

class MarkdownMessage extends StatelessWidget {
  final String text;
  final Color textColor;

  const MarkdownMessage({
    super.key,
    required this.text,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: text,
      builders: {
        'pre': CodeBlockBuilder(),
      },
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: textColor,
        ),
        h1: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h2: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h3: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        strong: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        blockquote: const TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
        listBullet: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          color: textColor,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final code = element.textContent;

    return CodeBlock(
      code: code,
      language: 'Code',
    );
  }
}