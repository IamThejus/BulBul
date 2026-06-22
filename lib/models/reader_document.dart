import 'readable_source.dart';

/// A single readable unit (an EPUB chapter, or a synthetic "page" we carve out
/// of a large HTML book). Holds raw HTML that the reader renders with
/// `flutter_html`.
class ReaderChapter {
  const ReaderChapter({required this.title, required this.html});

  final String title;
  final String html;
}

/// A fully-parsed book ready for the reader: normalized title/author, the source
/// [format], and an ordered list of [chapters]. Both the EPUB and HTML pipelines
/// converge on this shape, so the reader UI is source-agnostic.
class ReaderDocument {
  const ReaderDocument({
    required this.title,
    required this.author,
    required this.format,
    required this.chapters,
  });

  final String title;
  final String author;
  final ContentFormat format;
  final List<ReaderChapter> chapters;

  int get chapterCount => chapters.length;

  ReaderDocument copyWith({String? title, String? author}) => ReaderDocument(
        title: title ?? this.title,
        author: author ?? this.author,
        format: format,
        chapters: chapters,
      );
}
