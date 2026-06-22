/// App-wide non-network constants: Hive box names, storage keys, tunables and
/// UI spacing tokens. Centralizing these avoids typos in box names (which would
/// silently create the wrong box) and keeps spacing consistent app-wide.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Bulbul';

  // Hive boxes.
  static const String favoritesBox = 'favorites_box';
  static const String progressBox = 'reading_progress_box';
  static const String settingsBox = 'settings_box';

  // Settings keys (stored in [settingsBox]).
  static const String keyReaderFontSize = 'reader_font_size';
  static const String keyReaderLineHeight = 'reader_line_height';

  // Reader tunables.
  static const double minFontSize = 14.0;
  static const double maxFontSize = 30.0;
  static const double defaultFontSize = 18.0;
  static const double defaultLineHeight = 1.6;

  // Search tunables.
  static const Duration searchDebounce = Duration(milliseconds: 400);
  static const int searchPageSize = 20;
  static const int suggestionLimit = 12;

  // Spacing scale (kept small + consistent, Nothing-OS style).
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  static const double radius = 16.0;
  static const double radiusSm = 10.0;
}
