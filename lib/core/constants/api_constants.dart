/// Centralized API endpoints and configuration for every remote source Bulbul
/// talks to. Keeping these in one place makes it trivial to swap base URLs,
/// reason about the network surface, and keep services free of magic strings.
class ApiConstants {
  const ApiConstants._();

  // ---------------------------------------------------------------------------
  // Open Library — primary metadata provider (search, works, covers).
  // ---------------------------------------------------------------------------
  static const String openLibraryBase = 'https://openlibrary.org';
  static const String openLibrarySearch = '$openLibraryBase/search.json';

  /// Works endpoint is `/works/{workId}.json`.
  static String openLibraryWork(String workId) =>
      '$openLibraryBase/works/$workId.json';

  /// Cover service. [size] is one of `S`, `M`, `L`.
  static const String coversBase = 'https://covers.openlibrary.org/b';
  static String coverById(int coverId, {String size = 'L'}) =>
      '$coversBase/id/$coverId-$size.jpg';
  static String coverByOlid(String olid, {String size = 'L'}) =>
      '$coversBase/olid/$olid-$size.jpg';
  static String coverByIsbn(String isbn, {String size = 'L'}) =>
      '$coversBase/isbn/$isbn-$size.jpg';

  // ---------------------------------------------------------------------------
  // Project Gutenberg — primary readable-content source, via the Gutendex API.
  // Gutendex is the maintained JSON gateway over the Gutenberg catalogue and
  // exposes download formats (epub, html, text) per book.
  // ---------------------------------------------------------------------------
  static const String gutendexBase = 'https://gutendex.com';
  // NOTE: the trailing slash is required — `/books?...` 301-redirects to
  // `/books/?...`, and the redirect can drop the query, yielding empty results.
  static const String gutendexBooks = '$gutendexBase/books/';

  // ---------------------------------------------------------------------------
  // Internet Archive — secondary readable-content source.
  // ---------------------------------------------------------------------------
  static const String archiveBase = 'https://archive.org';
  static const String archiveSearch = '$archiveBase/advancedsearch.php';
  static String archiveMetadata(String identifier) =>
      '$archiveBase/metadata/$identifier';
  static String archiveDetails(String identifier) =>
      '$archiveBase/details/$identifier';
  static String archiveDownload(String identifier, String file) =>
      '$archiveBase/download/$identifier/$file';

  // ---------------------------------------------------------------------------
  // Networking defaults.
  // ---------------------------------------------------------------------------
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// A descriptive UA is requested by several of these public, free APIs.
  static const String userAgent =
      'Bulbul/1.0 (Flutter book reader; contact: app@bulbul.example)';
}
