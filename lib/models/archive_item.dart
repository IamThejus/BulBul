import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/constants/api_constants.dart';

part 'archive_item.g.dart';

/// A document from Internet Archive's `advancedsearch.php` response. Archive
/// fields are notoriously polymorphic (`creator` and `format` may each be a
/// string or a list), so both are normalized to `List<String>` on the way in.
@JsonSerializable()
class ArchiveItem extends Equatable {
  const ArchiveItem({
    required this.identifier,
    required this.title,
    this.creators = const [],
    this.year,
    this.mediaType,
    this.formats = const [],
    this.downloads = 0,
    this.isRestricted = false,
  });

  final String identifier;

  @JsonKey(defaultValue: 'Untitled')
  final String title;

  @JsonKey(name: 'creator', fromJson: _stringList)
  final List<String> creators;

  @JsonKey(fromJson: _yearToString)
  final String? year;

  @JsonKey(name: 'mediatype')
  final String? mediaType;

  @JsonKey(name: 'format', fromJson: _stringList)
  final List<String> formats;

  /// View/download count — Archive's popularity signal, used to rank editions.
  @JsonKey(fromJson: _toInt)
  final int downloads;

  /// True for lending-library / print-disabled / dark items whose files can't
  /// be freely downloaded. Read straight from the search doc so we can filter
  /// without a per-item metadata round-trip.
  @JsonKey(name: 'access-restricted-item', fromJson: _toBool)
  final bool isRestricted;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get authorLabel => creators.isEmpty ? 'Unknown author' : creators.join(', ');

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get detailsUrl => ApiConstants.archiveDetails(identifier);

  @JsonKey(includeFromJson: false, includeToJson: false)
  String get thumbnailUrl => '${ApiConstants.archiveBase}/services/img/$identifier';

  /// Best-effort online reader URL (works for most `texts` items).
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get readerUrl => '${ApiConstants.archiveBase}/stream/$identifier';

  factory ArchiveItem.fromJson(Map<String, dynamic> json) =>
      _$ArchiveItemFromJson(json);
  Map<String, dynamic> toJson() => _$ArchiveItemToJson(this);

  @override
  List<Object?> get props => [identifier, title];
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is String) return [value];
  if (value is List) return value.map((e) => e.toString()).toList();
  return const [];
}

String? _yearToString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _toBool(dynamic value) =>
    value == true || (value is String && value.toLowerCase() == 'true');
