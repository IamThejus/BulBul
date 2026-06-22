import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/constants/api_constants.dart';

part 'book.g.dart';

/// The core search-result entity, hydrated from an Open Library `search.json`
/// doc. It carries just enough to render a result/card and to seed a details or
/// reader flow (work id, title, authors, cover, and any Internet Archive ids we
/// can later use as a reading fallback).
@JsonSerializable()
class Book extends Equatable {
  const Book({
    required this.workId,
    required this.title,
    this.authors = const [],
    this.coverId,
    this.firstPublishYear,
    this.editionCount,
    this.medianPages,
    this.iaIdentifiers = const [],
    this.languages = const [],
  });

  /// Open Library returns `key` as `/works/OL123W`; we keep only the bare id.
  @JsonKey(name: 'key', fromJson: _workIdFromKey)
  final String workId;

  final String title;

  @JsonKey(name: 'author_name', defaultValue: <String>[])
  final List<String> authors;

  @JsonKey(name: 'cover_i')
  final int? coverId;

  @JsonKey(name: 'first_publish_year')
  final int? firstPublishYear;

  @JsonKey(name: 'edition_count')
  final int? editionCount;

  @JsonKey(name: 'number_of_pages_median')
  final int? medianPages;

  @JsonKey(name: 'ia', defaultValue: <String>[])
  final List<String> iaIdentifiers;

  @JsonKey(name: 'language', defaultValue: <String>[])
  final List<String> languages;

  // --- Derived, presentation-friendly helpers (ignored by codegen) ---

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get authorLabel => authors.isEmpty ? 'Unknown author' : authors.join(', ');

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get coverUrl => coverId != null ? ApiConstants.coverById(coverId!) : null;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get coverUrlMedium =>
      coverId != null ? ApiConstants.coverById(coverId!, size: 'M') : null;

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool get hasInternetArchive => iaIdentifiers.isNotEmpty;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  @override
  List<Object?> get props => [workId, title];
}

String _workIdFromKey(String key) =>
    key.startsWith('/works/') ? key.substring('/works/'.length) : key;
