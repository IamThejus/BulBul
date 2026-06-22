import '../models/book.dart';
import '../models/book_details.dart';
import '../services/open_library_service.dart';

/// Metadata repository — the single entry point the UI uses for discovery
/// (search, suggestions, details). It hides the fact that everything here comes
/// from Open Library, so swapping/adding a metadata provider later wouldn't ripple
/// into the feature layer.
class BookRepository {
  BookRepository(this._openLibrary);

  final OpenLibraryService _openLibrary;

  Future<BookSearchPage> search(String query, {int page = 1, int limit = 20}) {
    return _openLibrary.search(query.trim(), page: page, limit: limit);
  }

  Future<List<Book>> suggestions(String query, {int limit = 12}) {
    return _openLibrary.suggestions(query.trim(), limit: limit);
  }

  Future<BookDetails> details(String workId) => _openLibrary.workDetails(workId);
}
