import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/gutenberg_book.dart';

/// Talks to Project Gutenberg via the Gutendex API — Bulbul's primary source of
/// actually-readable, public-domain content. We search by title (+ author) and
/// then pick a book that exposes an EPUB or HTML download.
class GutenbergService {
  GutenbergService(this._dio);

  final Dio _dio;

  Future<List<GutenbergBook>> search({
    required String title,
    String? author,
  }) async {
    final query = [
      title.trim(),
      if (author != null && author.trim().isNotEmpty) author.trim(),
    ].join(' ');

    final res = await _dio.safe(
      () => _dio.get<Map<String, dynamic>>(
        ApiConstants.gutendexBooks,
        queryParameters: {'search': query},
      ),
    );

    final results = (res.data?['results'] as List?) ?? const [];
    return results
        .whereType<Map>()
        .map((e) => GutenbergBook.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Finds the best readable match for a title/author: prefers a result that
  /// actually exposes EPUB/HTML, falling back to the top hit.
  Future<GutenbergBook?> findReadable({
    required String title,
    String? author,
  }) async {
    final results = await search(title: title, author: author);
    if (results.isEmpty) return null;
    for (final book in results) {
      if (book.isReadable) return book;
    }
    return results.first;
  }
}
