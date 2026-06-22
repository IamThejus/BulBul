// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'author.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Author _$AuthorFromJson(Map<String, dynamic> json) => Author(
  key: _idFromKey(json['key'] as String),
  name: json['name'] as String,
  bio: _bioFromJson(json['bio']),
  birthDate: json['birth_date'] as String?,
  deathDate: json['death_date'] as String?,
);

Map<String, dynamic> _$AuthorToJson(Author instance) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'bio': instance.bio,
  'birth_date': instance.birthDate,
  'death_date': instance.deathDate,
};
