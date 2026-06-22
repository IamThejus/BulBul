// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
  workId: _workIdFromKey(json['key'] as String),
  title: json['title'] as String,
  authors:
      (json['author_name'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  coverId: (json['cover_i'] as num?)?.toInt(),
  firstPublishYear: (json['first_publish_year'] as num?)?.toInt(),
  editionCount: (json['edition_count'] as num?)?.toInt(),
  medianPages: (json['number_of_pages_median'] as num?)?.toInt(),
  iaIdentifiers:
      (json['ia'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  languages:
      (json['language'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
  'key': instance.workId,
  'title': instance.title,
  'author_name': instance.authors,
  'cover_i': instance.coverId,
  'first_publish_year': instance.firstPublishYear,
  'edition_count': instance.editionCount,
  'number_of_pages_median': instance.medianPages,
  'ia': instance.iaIdentifiers,
  'language': instance.languages,
};
