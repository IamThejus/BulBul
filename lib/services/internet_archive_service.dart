import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/archive_item.dart';
import '../models/readable_source.dart';

/// Talks to the Internet Archive — Bulbul's *secondary* reading source, used
/// when Gutenberg has nothing. We query the `texts` collection and, when needed,
/// drill into an item's metadata to find a directly-renderable HTML/EPUB file.
class InternetArchiveService {
  InternetArchiveService(this._dio);

  final Dio _dio;

  /// Searches the `texts` collection for a title, ranked by popularity
  /// (downloads/views) exactly like the archive.org website. We query the title
  /// only — community uploads frequently have a missing or differently-formatted
  /// `creator`, so hard-ANDing the author would wrongly exclude readable copies;
  /// the downloads ranking already surfaces the right edition. The
  /// `access-restricted-item` and `downloads` fields ride along so the caller
  /// can filter + rank without a per-item metadata round-trip.
  Future<List<ArchiveItem>> search({
    required String title,
    int rows = 20,
  }) async {
    final res = await _dio.safe(
      () => _dio.get<Map<String, dynamic>>(
        ApiConstants.archiveSearch,
        queryParameters: {
          'q': 'title:(${_sanitize(title)}) AND mediatype:texts',
          'fl[]': const [
            'identifier',
            'title',
            'creator',
            'year',
            'mediatype',
            'format',
            'downloads',
            'access-restricted-item',
          ],
          'sort[]': 'downloads desc',
          'rows': rows,
          'page': 1,
          'output': 'json',
        },
      ),
    );

    final docs = (res.data?['response']?['docs'] as List?) ?? const [];
    return docs
        .whereType<Map>()
        .map((e) => ArchiveItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Full metadata (including the `files` array) for a given identifier. Used to
  /// locate a concrete readable file and to build a direct download URL.
  ///
  /// Crucially, this also reads the item's *access restriction*: lending-library
  /// / print-disabled / "dark" items expose `.epub`/`.html` files that are NOT
  /// freely downloadable — fetching them 302-redirects to a login wall and then
  /// 401s. We surface that as [ArchiveMetadata.isRestricted] so the repository
  /// degrades to "available externally" instead of triggering a failed download.
  Future<ArchiveMetadata> metadata(String identifier) async {
    final res = await _dio.safe(
      () => _dio.get<Map<String, dynamic>>(
        ApiConstants.archiveMetadata(identifier),
      ),
    );
    final data = res.data ?? const {};
    final meta = (data['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};

    final collections = _asStringList(meta['collection']).map((c) => c.toLowerCase());
    const restrictedCollections = {'inlibrary', 'printdisabled', 'lendinglibrary'};
    final isRestricted = _isTruthy(meta['access-restricted-item']) ||
        _isTruthy(data['is_dark']) ||
        collections.any(restrictedCollections.contains);

    final files = ((data['files'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    return ArchiveMetadata(
      identifier: identifier,
      files: files,
      isRestricted: isRestricted,
    );
  }

  /// Strips Lucene control characters so user input can't break the query.
  String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[:"\(\)\[\]\{\}\^~*?\\]'), ' ').trim();

  static bool _isTruthy(dynamic v) =>
      v == true || v == 1 || (v is String && v.toLowerCase() == 'true');

  static List<String> _asStringList(dynamic v) {
    if (v == null) return const [];
    if (v is String) return [v];
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }
}

/// Minimal view over an Archive item's metadata: just the file list, plus
/// helpers to find a renderable HTML/EPUB file and form its download URL.
class ArchiveMetadata {
  const ArchiveMetadata({
    required this.identifier,
    required this.files,
    this.isRestricted = false,
  });

  final String identifier;
  final List<Map<String, dynamic>> files;

  /// When true, the item is lending-restricted/dark and its files cannot be
  /// freely downloaded for in-app rendering (only read externally).
  final bool isRestricted;

  /// The best in-app-renderable file as `(downloadUrl, format)`, preferring a
  /// clean EPUB, then plain OCR text (`_djvu.txt`), then HTML. Null when the
  /// item is restricted or exposes nothing renderable (e.g. PDF-only).
  ({String url, ContentFormat format})? get readable {
    if (isRestricted) return null;

    final epub = _firstFileWithExtension(const ['.epub']);
    if (epub != null) {
      return (
        url: ApiConstants.archiveDownload(identifier, epub),
        format: ContentFormat.epub,
      );
    }
    final text = _firstFileWithExtension(const ['_djvu.txt', '.txt']);
    if (text != null) {
      return (
        url: ApiConstants.archiveDownload(identifier, text),
        format: ContentFormat.text,
      );
    }
    final html = _firstFileWithExtension(const ['.html', '.htm']);
    if (html != null) {
      return (
        url: ApiConstants.archiveDownload(identifier, html),
        format: ContentFormat.html,
      );
    }
    return null;
  }

  /// First file whose name ends with one of [exts], honouring the *priority
  /// order of [exts]* (not file order) so we prefer cleaner formats.
  String? _firstFileWithExtension(List<String> exts) {
    for (final ext in exts) {
      for (final f in files) {
        final name = f['name'] as String?;
        if (name != null && name.toLowerCase().endsWith(ext)) return name;
      }
    }
    return null;
  }
}
