import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';

int getWordCount(quill.QuillController controller) {
  final text = controller.document.toPlainText();
  return text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;
}

int getCharacterCount(quill.QuillController controller) {
  return controller.document.toPlainText().trim().length;
}

int estimateReadingMinutes(quill.QuillController controller) {
  final words = getWordCount(controller);
  if (words == 0) return 0;
  return ((words - 1) ~/ 220) + 1;
}

quill.Document documentFromMarkdown(String markdown) {
  if (markdown.trim().isEmpty) return quill.Document();

  try {
    final delta = MarkdownToDelta(
      markdownDocument: md.Document(),
    ).convert(markdown);
    return quill.Document.fromDelta(delta);
  } catch (_) {
    final doc = quill.Document();
    doc.insert(0, markdown);
    return doc;
  }
}

String markdownFromDocument(quill.Document document) {
  final plain = document.toPlainText().trim();
  if (plain.isEmpty) return '';

  try {
    return DeltaToMarkdown().convert(document.toDelta()).trimRight();
  } catch (_) {
    return document.toPlainText().trimRight();
  }
}

bool documentHasRichFormatting(quill.Document document) {
  final ops = document.toDelta().toJson();
  for (final op in ops) {
    final attrs = op['attributes'];
    final insert = op['insert'];
    if (attrs is Map && attrs.isNotEmpty) return true;
    if (insert is! String) return true;
  }
  return false;
}

String deltaSignature(quill.Document document) {
  return jsonEncode(document.toDelta().toJson());
}

bool looksLikeMarkdown(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;

  const pattern =
      r'(^|\n)\s{0,3}(#{1,3})\s+|\*\*[^*]+\*\*|\*[^*\n]+\*|(^|\n)\s*[-*]\s+|(^|\n)\s*>\s+|!\[[^\]]*\]\([^)]+\)|\[[^\]]+\]\([^)]+\)';

  return RegExp(pattern, multiLine: true).hasMatch(value);
}

String fingerprintFor(String title, String content) {
  return '$title::$content';
}

String markdownForPreview(quill.QuillController controller) {
  final plain = controller.document.toPlainText().trimRight();
  if (plain.isEmpty) return '*Start writing...*';

  if (!documentHasRichFormatting(controller.document)) return plain;

  final serialized = markdownFromDocument(controller.document);
  return serialized.isEmpty ? plain : serialized;
}
