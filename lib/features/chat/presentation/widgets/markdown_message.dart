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
    final colors = Theme.of(context).colorScheme;

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
        blockquote: TextStyle(
          color: colors.onSurfaceVariant,
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
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant,
          ),
        ),
        a: TextStyle(
          color: colors.primary,
          decoration: TextDecoration.underline,
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