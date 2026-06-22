// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArchiveItem _$ArchiveItemFromJson(Map<String, dynamic> json) => ArchiveItem(
  identifier: json['identifier'] as String,
  title: json['title'] as String? ?? 'Untitled',
  creators: json['creator'] == null ? const [] : _stringList(json['creator']),
  year: _yearToString(json['year']),
  mediaType: json['mediatype'] as String?,
  formats: json['format'] == null ? const [] : _stringList(json['format']),
  downloads: json['downloads'] == null ? 0 : _toInt(json['downloads']),
  isRestricted: json['access-restricted-item'] == null
      ? false
      : _toBool(json['access-restricted-item']),
);

Map<String, dynamic> _$ArchiveItemToJson(ArchiveItem instance) =>
    <String, dynamic>{
      'identifier': instance.identifier,
      'title': instance.title,
      'creator': instance.creators,
      'year': instance.year,
      'mediatype': instance.mediaType,
      'format': instance.formats,
      'downloads': instance.downloads,
      'access-restricted-item': instance.isRestricted,
    };
