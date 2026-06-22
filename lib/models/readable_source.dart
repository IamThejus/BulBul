import 'package:equatable/equatable.dart';

/// Concrete content format the reader knows how to render. `text` is plain
/// text (common for Internet Archive `_djvu.txt` files) that we paragraph-wrap
/// into HTML at load time.
enum ContentFormat { epub, html, text }

/// Where the readable content was sourced from.
enum SourceProvider { gutenberg, internetArchive }

/// The result of "where/how can I actually read this book?". The repository
/// resolves an abstract [Book] into a [ReadableSource] (or null if nothing is
/// freely readable), which the reader then loads. This is the seam between
/// "metadata land" (Open Library) and "content land" (Gutenberg / Archive).
class ReadableSource extends Equatable {
  const ReadableSource({
    required this.format,
    required this.url,
    required this.provider,
    this.title,
    this.onlineReaderUrl,
  });

  final ContentFormat format;

  /// Direct URL to the EPUB/HTML content to download and render in-app.
  final String url;

  final SourceProvider provider;
  final String? title;

  /// For sources we can't render in-app (e.g. some Archive items), an external
  /// URL where the user can read it legally in a browser.
  final String? onlineReaderUrl;

  bool get isEpub => format == ContentFormat.epub;
  bool get isHtml => format == ContentFormat.html;
  bool get isText => format == ContentFormat.text;

  /// True when we have a real content URL to download and render in-app (vs. an
  /// availability-only result that merely points at an external reader).
  bool get isInAppReadable => url.isNotEmpty;

  String get providerLabel => switch (provider) {
        SourceProvider.gutenberg => 'Project Gutenberg',
        SourceProvider.internetArchive => 'Internet Archive',
      };

  String get formatLabel => switch (format) {
        ContentFormat.epub => 'EPUB',
        ContentFormat.html => 'HTML',
        ContentFormat.text => 'Text',
      };

  @override
  List<Object?> get props => [format, url, provider];
}
