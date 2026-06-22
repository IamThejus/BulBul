import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gutenberg_book.g.dart';

/// A Project Gutenberg title as returned by the Gutendex API. The crucial field
/// is [formats]: a MIME→URL map from which we extract an EPUB or HTML edition to
/// open in Bulbul's reader.
@JsonSerializable()
class GutenbergBook extends Equatable {
  const GutenbergBook({
    required this.id,
    required this.title,
    this.authors = const [],
    this.languages = const [],
    this.formats = const {},
    this.downloadCount = 0,
  });

  final int id;

  @JsonKey(defaultValue: 'Untitled')
  final String title;

  @JsonKey(defaultValue: <GutenbergAuthor>[])
  final List<GutenbergAuthor> authors;

  @JsonKey(defaultValue: <String>[])
  final List<String> languages;

  @JsonKey(defaultValue: <String, String>{})
  final Map<String, String> formats;

  @JsonKey(name: 'download_count', defaultValue: 0)
  final int downloadCount;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get authorLabel =>
      authors.isEmpty ? 'Unknown author' : authors.map((a) => a.name).join(', ');

  /// Prefer the EPUB without `.images` (smaller, cleaner) but accept any EPUB.
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get epubUrl {
    final entry = formats.entries.where((e) => e.key.contains('epub'));
    if (entry.isEmpty) return null;
    return entry
        .map((e) => e.value)
        .firstWhere((u) => !u.endsWith('.noimages'), orElse: () => entry.first.value);
  }

  /// A readable HTML edition (excluding the zip variants).
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get htmlUrl {
    for (final e in formats.entries) {
      if (e.key.startsWith('text/html') && !e.value.endsWith('.zip')) {
        return e.value;
      }
    }
    return null;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get plainTextUrl {
    for (final e in formats.entries) {
      if (e.key.startsWith('text/plain') && !e.value.endsWith('.zip')) {
        return e.value;
      }
    }
    return null;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get isReadable => epubUrl != null || htmlUrl != null || plainTextUrl != null;

  factory GutenbergBook.fromJson(Map<String, dynamic> json) =>
      _$GutenbergBookFromJson(json);
  Map<String, dynamic> toJson() => _$GutenbergBookToJson(this);

  @override
  List<Object?> get props => [id, title];
}

@JsonSerializable()
class GutenbergAuthor extends Equatable {
  const GutenbergAuthor({required this.name, this.birthYear, this.deathYear});

  @JsonKey(defaultValue: 'Unknown')
  final String name;

  @JsonKey(name: 'birth_year')
  final int? birthYear;

  @JsonKey(name: 'death_year')
  final int? deathYear;

  factory GutenbergAuthor.fromJson(Map<String, dynamic> json) =>
      _$GutenbergAuthorFromJson(json);
  Map<String, dynamic> toJson() => _$GutenbergAuthorToJson(this);

  @override
  List<Object?> get props => [name];
}
