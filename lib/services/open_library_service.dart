import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/book.dart';
import '../models/book_details.dart';

/// One page of Open Library search results plus the total match count, which the
/// search feature uses to drive pagination ("load more").
typedef BookSearchPage = ({List<Book> books, int numFound});

/// Talks to Open Library — Bulbul's primary metadata provider. We always pass an
/// explicit `fields` list to keep responses small (covers, titles, authors),
/// which matters for the as-you-type suggestion path.
class OpenLibraryService {
  OpenLibraryService(this._dio);

  final Dio _dio;

  static const String _searchFields =
      'key,title,author_name,author_key,cover_i,first_publish_year,'
      'edition_count,number_of_pages_median,ia,language';

  static const String _suggestFields =
      'key,title,author_name,cover_i,first_publish_year,ia';

  /// Full, paginated search used by the search results list.
  Future<BookSearchPage> search(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safe(
      () => _dio.get<Map<String, dynamic>>(
        ApiConstants.openLibrarySearch,
        queryParameters: {
          'q': query,
          'page': page,
          'limit': limit,
          'fields': _searchFields,
        },
      ),
    );

    final data = res.data ?? const {};
    final docs = (data['docs'] as List?) ?? const [];
    final books = docs
        .whereType<Map>()
        .map((e) => Book.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return (books: books, numFound: (data['numFound'] as num?)?.toInt() ?? books.length);
  }

  /// Lightweight, capped query for autocomplete suggestions.
  Future<List<Book>> suggestions(String query, {int limit = 12}) async {
    final res = await _dio.safe(
      () => _dio.get<Map<String, dynamic>>(
        ApiConstants.openLibrarySearch,
        queryParameters: {
          'q': query,
          'limit': limit,
          'fields': _suggestFields,
        },
      ),
    );

    final docs = (res.data?['docs'] as List?) ?? const [];
    return docs
        .whereType<Map>()
        .map((e) => Book.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Full work record for the details screen.
  Future<BookDetails> workDetails(String workId) async {
    final res = await _dio.safe(
      () => _dio.get<Map<String, dynamic>>(ApiConstants.openLibraryWork(workId)),
    );
    return BookDetails.fromJson(res.data ?? const {});
  }
}
