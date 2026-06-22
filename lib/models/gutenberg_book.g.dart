// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gutenberg_book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GutenbergBook _$GutenbergBookFromJson(Map<String, dynamic> json) =>
    GutenbergBook(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? 'Untitled',
      authors:
          (json['authors'] as List<dynamic>?)
              ?.map((e) => GutenbergAuthor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      languages:
          (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      formats:
          (json['formats'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as String),
          ) ??
          {},
      downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$GutenbergBookToJson(GutenbergBook instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'authors': instance.authors,
      'languages': instance.languages,
      'formats': instance.formats,
      'download_count': instance.downloadCount,
    };

GutenbergAuthor _$GutenbergAuthorFromJson(Map<String, dynamic> json) =>
    GutenbergAuthor(
      name: json['name'] as String? ?? 'Unknown',
      birthYear: (json['birth_year'] as num?)?.toInt(),
      deathYear: (json['death_year'] as num?)?.toInt(),
    );

Map<String, dynamic> _$GutenbergAuthorToJson(GutenbergAuthor instance) =>
    <String, dynamic>{
      'name': instance.name,
      'birth_year': instance.birthYear,
      'death_year': instance.deathYear,
    };
