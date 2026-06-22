import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/readable_source.dart';
import '../../../models/reading_progress.dart';
import '../../../services/hive_service.dart';

/// Reader background/ink themes. The app canvas is pure black; these only affect
/// the *reading surface*, giving Kindle-style comfort options while staying dark.
enum ReaderTheme { dark, dim, sepia }

/// Persisted, user-tunable reading preferences (font size, line height, theme).
class ReaderSettings extends Equatable {
  const ReaderSettings({
    required this.fontSize,
    required this.lineHeight,
    required this.theme,
  });

  final double fontSize;
  final double lineHeight;
  final ReaderTheme theme;

  ReaderSettings copyWith({
    double? fontSize,
    double? lineHeight,
    ReaderTheme? theme,
  }) {
    return ReaderSettings(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [fontSize, lineHeight, theme];
}

/// Loads/saves [ReaderSettings] from the Hive settings box so preferences
/// persist across sessions. All reader instances share one settings object.
class ReaderSettingsNotifier extends Notifier<ReaderSettings> {
  static const _themeKey = 'reader_theme';

  @override
  ReaderSettings build() {
    final box = HiveService.settingsBox;
    return ReaderSettings(
      fontSize: (box.get(AppConstants.keyReaderFontSize) as num?)?.toDouble() ??
          AppConstants.defaultFontSize,
      lineHeight:
          (box.get(AppConstants.keyReaderLineHeight) as num?)?.toDouble() ??
              AppConstants.defaultLineHeight,
      theme: ReaderTheme.values[(box.get(_themeKey) as int?) ?? 0],
    );
  }

  void increaseFont() => _setFont(state.fontSize + 1);
  void decreaseFont() => _setFont(state.fontSize - 1);

  void _setFont(double value) {
    final clamped = value.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    HiveService.settingsBox.put(AppConstants.keyReaderFontSize, clamped);
    state = state.copyWith(fontSize: clamped.toDouble());
  }

  void setLineHeight(double value) {
    final clamped = value.clamp(1.2, 2.2).toDouble();
    HiveService.settingsBox.put(AppConstants.keyReaderLineHeight, clamped);
    state = state.copyWith(lineHeight: clamped);
  }

  void setTheme(ReaderTheme theme) {
    HiveService.settingsBox.put(_themeKey, theme.index);
    state = state.copyWith(theme: theme);
  }
}

final readerSettingsProvider =
    NotifierProvider<ReaderSettingsNotifier, ReaderSettings>(
  ReaderSettingsNotifier.new,
);

/// Everything the reader needs to open (and later resume) a book. Passed via the
/// router as `extra`. [id] is the canonical progress key (work id when known).
///
/// When [source] is provided (the "resume" path from Continue Reading), the
/// reader skips the slow Gutenberg/Archive resolution and loads it directly.
class ReaderArgs extends Equatable {
  const ReaderArgs({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    this.iaIdentifiers = const [],
    this.source,
  });

  /// Builds args that resume an existing [ReadingProgress] without re-resolving
  /// the reading source.
  factory ReaderArgs.resume(ReadingProgress p) => ReaderArgs(
        id: p.id,
        title: p.title,
        author: p.author,
        coverUrl: p.coverUrl,
        source: ReadableSource(
          format: p.isEpub
              ? ContentFormat.epub
              : (p.isText ? ContentFormat.text : ContentFormat.html),
          url: p.contentUrl,
          provider: p.provider == 'internetArchive'
              ? SourceProvider.internetArchive
              : SourceProvider.gutenberg,
          title: p.title,
        ),
      );

  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final List<String> iaIdentifiers;
  final ReadableSource? source;

  @override
  List<Object?> get props =>
      [id, title, author, coverUrl, iaIdentifiers, source];
}
