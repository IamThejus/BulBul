import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/constants/api_constants.dart';

part 'book_details.g.dart';

/// Rich metadata from Open Library's `/works/{id}.json`. The work endpoint is
/// quirky: `description` can be a string OR a `{type, value}` object, and
/// `covers` can contain `-1` sentinels — both are normalized here so the UI
/// never has to special-case the wire format.
@JsonSerializable()
class BookDetails extends Equatable {
  const BookDetails({
    required this.workId,
    required this.title,
    this.description,
    this.coverIds = const [],
    this.subjects = const [],
    this.firstPublishDate,
  });

  @JsonKey(name: 'key', fromJson: _workIdFromKey)
  final String workId;

  @JsonKey(defaultValue: 'Untitled')
  final String title;

  @JsonKey(fromJson: _descriptionFromJson)
  final String? description;

  @JsonKey(name: 'covers', defaultValue: <int>[])
  final List<int> coverIds;

  @JsonKey(defaultValue: <String>[])
  final List<String> subjects;

  @JsonKey(name: 'first_publish_date')
  final String? firstPublishDate;

  @JsonKey(includeFromJson: false, includeToJson: false)
  int? get primaryCoverId {
    for (final id in coverIds) {
      if (id > 0) return id;
    }
    return null;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get coverUrl =>
      primaryCoverId != null ? ApiConstants.coverById(primaryCoverId!) : null;

  factory BookDetails.fromJson(Map<String, dynamic> json) =>
      _$BookDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$BookDetailsToJson(this);

  @override
  List<Object?> get props => [workId, title, description];
}

String _workIdFromKey(String key) =>
    key.startsWith('/works/') ? key.substring('/works/'.length) : key;

/// Open Library `description` is either a plain string or `{type, value}`.
String? _descriptionFromJson(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.trim();
  if (value is Map<String, dynamic>) {
    final v = value['value'];
    return v is String ? v.trim() : null;
  }
  return null;
}
