// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookDetails _$BookDetailsFromJson(Map<String, dynamic> json) => BookDetails(
  workId: _workIdFromKey(json['key'] as String),
  title: json['title'] as String? ?? 'Untitled',
  description: _descriptionFromJson(json['description']),
  coverIds:
      (json['covers'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      [],
  subjects:
      (json['subjects'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  firstPublishDate: json['first_publish_date'] as String?,
);

Map<String, dynamic> _$BookDetailsToJson(BookDetails instance) =>
    <String, dynamic>{
      'key': instance.workId,
      'title': instance.title,
      'description': instance.description,
      'covers': instance.coverIds,
      'subjects': instance.subjects,
      'first_publish_date': instance.firstPublishDate,
    };
