/// Canonical route locations. Centralizing avoids stringly-typed navigation
/// scattered across the app and gives one place to evolve the URL scheme.
class RoutePaths {
  const RoutePaths._();

  static const String home = '/home';
  static const String search = '/search';
  static const String favorites = '/favorites';

  static const String bookDetails = '/book';
  static String bookDetailsOf(String workId) => '/book/$workId';

  static const String reader = '/reader';
}
