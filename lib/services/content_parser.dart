import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart';

import '../models/readable_source.dart';
import '../models/reader_document.dart';

/// Turns raw bytes/strings from a [ReadableSource] into a render-ready
/// [ReaderDocument]. Two pipelines converge here:
///
///  * EPUB  → unzip + parse via `epubx`, flatten the chapter tree.
///  * HTML  → extract `<body>`, sanitize, and chunk into page-sized chapters.
///
/// EPUB parsing (unzip + XML) is CPU-heavy, so it runs on a background isolate
/// via [compute]; the resulting [ReaderDocument] holds only sendable primitives.
class ContentParser {
  const ContentParser._();

  /// Roughly how many characters of HTML go into one synthetic HTML "page".
  /// Keeps each `flutter_html` widget tree small enough to stay smooth.
  static const int _htmlChunkSize = 6000;

  static Future<ReaderDocument> parseEpub(
    List<int> bytes, {
    required String fallbackTitle,
    required String fallbackAuthor,
  }) async {
    final doc = await compute(_parseEpubInIsolate, bytes);
    return doc.copyWith(
      title: doc.title.trim().isEmpty ? fallbackTitle : doc.title,
      author: doc.author.trim().isEmpty ? fallbackAuthor : doc.author,
    );
  }

  static ReaderDocument parseHtml(
    String rawHtml, {
    required String title,
    required String author,
  }) {
    final body = _extractBody(rawHtml);
    final chapters = _chunkHtml(_sanitizeHtml(body));
    return ReaderDocument(
      title: title,
      author: author,
      format: ContentFormat.html,
      chapters: chapters.isEmpty
          ? const [ReaderChapter(title: 'Start', html: '<p>Empty document.</p>')]
          : chapters,
    );
  }

  /// Converts plain text (e.g. an Internet Archive `_djvu.txt`) into paragraph
  /// HTML and chunks it. Blank lines delimit paragraphs; single newlines inside
  /// a paragraph become spaces. Text is HTML-escaped so stray `<`/`&` are safe.
  static ReaderDocument parseText(
    String rawText, {
    required String title,
    required String author,
  }) {
    final escaped = rawText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    final paragraphs = escaped
        .split(RegExp(r'\n[ \t]*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => '<p>${p.replaceAll(RegExp(r'\s*\n\s*'), ' ')}</p>');
    final chapters = _chunkHtml(paragraphs.join('\n'));
    return ReaderDocument(
      title: title,
      author: author,
      format: ContentFormat.text,
      chapters: chapters.isEmpty
          ? const [ReaderChapter(title: 'Start', html: '<p>Empty document.</p>')]
          : chapters,
    );
  }

  static List<ReaderChapter> _chunkHtml(String body) {
    // Split *before* block-level tags so we never cut inside a tag.
    final blocks = body.split(
      RegExp(r'(?=<(?:p|div|h[1-6]|blockquote|section)[\s>])',
          caseSensitive: false),
    );

    final chapters = <ReaderChapter>[];
    final buffer = StringBuffer();
    var count = 0;
    var page = 1;

    void flush() {
      if (buffer.toString().trim().isEmpty) return;
      chapters.add(ReaderChapter(title: 'Page $page', html: buffer.toString()));
      page++;
      buffer.clear();
      count = 0;
    }

    for (final block in blocks) {
      buffer.write(block);
      count += block.length;
      if (count >= _htmlChunkSize) flush();
    }
    flush();
    return chapters;
  }
}

/// Top-level so it can run in a [compute] isolate.
Future<ReaderDocument> _parseEpubInIsolate(List<int> bytes) async {
  final book = await EpubReader.readBook(bytes);
  final chapters = <ReaderChapter>[];

  void walk(List<EpubChapter>? nodes) {
    if (nodes == null) return;
    for (final node in nodes) {
      final html = node.HtmlContent;
      if (html != null && html.trim().isNotEmpty) {
        final title = (node.Title?.trim().isNotEmpty ?? false)
            ? node.Title!.trim()
            : 'Chapter ${chapters.length + 1}';
        chapters.add(ReaderChapter(title: title, html: _sanitizeHtml(html)));
      }
      walk(node.SubChapters);
    }
  }

  walk(book.Chapters);

  // Some EPUBs have an empty TOC; fall back to the raw HTML content files.
  if (chapters.isEmpty) {
    final htmlFiles = book.Content?.Html;
    if (htmlFiles != null) {
      var i = 1;
      for (final entry in htmlFiles.entries) {
        final content = entry.value.Content;
        if (content != null && content.trim().isNotEmpty) {
          chapters.add(ReaderChapter(
            title: 'Section ${i++}',
            html: _sanitizeHtml(_extractBody(content)),
          ));
        }
      }
    }
  }

  return ReaderDocument(
    title: book.Title ?? '',
    author: book.Author ?? (book.AuthorList?.whereType<String>().join(', ') ?? ''),
    format: ContentFormat.epub,
    chapters: chapters.isEmpty
        ? const [
            ReaderChapter(
              title: 'Notice',
              html: '<p>This book could not be displayed.</p>',
            )
          ]
        : chapters,
  );
}

/// Pulls out the `<body>` inner HTML if present (top-level so the isolate fn
/// can use it too).
String _extractBody(String html) {
  final match = RegExp(r'<body[^>]*>([\s\S]*?)</body>', caseSensitive: false)
      .firstMatch(html);
  return match?.group(1) ?? html;
}

/// Removes elements `flutter_html` can't usefully render in an offline reader
/// (images with unresolved relative paths, scripts, styles, svg) so the page
/// stays clean and light.
String _sanitizeHtml(String html) {
  return html
      .replaceAll(RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<svg[\s\S]*?</svg>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<img[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<image[^>]*>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<link[^>]*>', caseSensitive: false), '');
}
