import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/readable_source.dart';
import '../models/reader_document.dart';
import '../models/reading_progress.dart';
import '../services/content_parser.dart';
import '../services/gutenberg_service.dart';
import '../services/internet_archive_service.dart';
import '../services/reading_progress_service.dart';

/// The heart of the reading experience. This repository:
///
///  1. **Resolves** an abstract book (title/author/IA ids) into a concrete
///     [ReadableSource], trying Project Gutenberg first and Internet Archive
///     second (the spec's primary/secondary ordering).
///  2. **Loads** that source into a render-ready [ReaderDocument] (download +
///     parse EPUB/HTML).
///  3. **Persists** reading progress via [ReadingProgressService].
///
/// Source resolution deliberately swallows per-provider errors and falls
/// through, so a Gutenberg hiccup still lets Archive answer.
class ReadingRepository {
  ReadingRepository({
    required Dio dio,
    required GutenbergService gutenberg,
    required InternetArchiveService archive,
    required ReadingProgressService progress,
  })  : _dio = dio,
        _gutenberg = gutenberg,
        _archive = archive,
        _progress = progress;

  final Dio _dio;
  final GutenbergService _gutenberg;
  final InternetArchiveService _archive;
  final ReadingProgressService _progress;

  // ---------------------------------------------------------------------------
  // Source resolution
  // ---------------------------------------------------------------------------

  Future<ReadableSource?> resolveSource({
    required String title,
    required String author,
    List<String> iaIdentifiers = const [],
  }) async {
    final cleanAuthor =
        (author.isEmpty || author == 'Unknown author') ? null : author;

    // 1) Project Gutenberg — preferred (clean EPUB/HTML, in-app renderable).
    try {
      final g = await _gutenberg.findReadable(title: title, author: cleanAuthor);
      if (g != null) {
        if (g.epubUrl != null) {
          return ReadableSource(
            format: ContentFormat.epub,
            url: g.epubUrl!,
            provider: SourceProvider.gutenberg,
            title: g.title,
          );
        }
        if (g.htmlUrl != null) {
          return ReadableSource(
            format: ContentFormat.html,
            url: g.htmlUrl!,
            provider: SourceProvider.gutenberg,
            title: g.title,
          );
        }
      }
    } catch (_) {
      // fall through to Internet Archive
    }

    // 2) Internet Archive — secondary. Search the texts collection ranked by
    //    views (like the website), skip lending-restricted items up front, then
    //    inspect the top few non-restricted candidates for a renderable
    //    EPUB/text/HTML file. If nothing renders, surface external availability
    //    so the user can still read it legally in a browser.
    try {
      final ranked = await _archive.search(title: title);
      final candidates = <String>[
        // Known non-restricted, most-viewed editions first…
        ...ranked.where((i) => !i.isRestricted).map((i) => i.identifier),
        // …then any Open-Library-supplied ids (often restricted scans).
        ...iaIdentifiers,
      ];

      final tried = <String>{};
      for (final id in candidates) {
        if (tried.length >= 6) break; // bound metadata round-trips
        if (!tried.add(id)) continue;

        final meta = await _archive.metadata(id);
        final readable = meta.readable;
        if (readable != null) {
          return ReadableSource(
            format: readable.format,
            url: readable.url,
            provider: SourceProvider.internetArchive,
            title: title,
            onlineReaderUrl: ApiConstants.archiveDetails(id),
          );
        }
      }

      // Available on Archive (most-viewed match), but not renderable in-app.
      final fallbackId = ranked.isNotEmpty
          ? ranked.first.identifier
          : (iaIdentifiers.isNotEmpty ? iaIdentifiers.first : null);
      if (fallbackId != null) {
        return ReadableSource(
          format: ContentFormat.html,
          url: '',
          provider: SourceProvider.internetArchive,
          title: title,
          onlineReaderUrl: ApiConstants.archiveDetails(fallbackId),
        );
      }
    } catch (_) {
      // nothing readable
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Content loading
  // ---------------------------------------------------------------------------

  Future<ReaderDocument> loadDocument(
    ReadableSource source, {
    required String title,
    required String author,
  }) async {
    if (source.isEpub) {
      final res = await _dio.safe(
        () => _dio.get<List<int>>(
          source.url,
          options: Options(responseType: ResponseType.bytes),
        ),
      );
      return ContentParser.parseEpub(
        res.data ?? const <int>[],
        fallbackTitle: title,
        fallbackAuthor: author,
      );
    }

    final res = await _dio.safe(
      () => _dio.get<String>(
        source.url,
        options: Options(responseType: ResponseType.plain),
      ),
    );
    final raw = res.data ?? '';
    return source.isText
        ? ContentParser.parseText(raw, title: title, author: author)
        : ContentParser.parseHtml(raw, title: title, author: author);
  }

  // ---------------------------------------------------------------------------
  // Reading progress
  // ---------------------------------------------------------------------------

  ReadingProgress? progressFor(String id) => _progress.get(id);

  Future<void> saveProgress(ReadingProgress progress) =>
      _progress.save(progress);

  Future<void> removeProgress(String id) => _progress.remove(id);

  List<ReadingProgress> continueReading() => _progress.getContinueReading();

  ValueListenable<Box<ReadingProgress>> progressListenable() =>
      _progress.listenable();
}
