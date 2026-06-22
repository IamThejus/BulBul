import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'author.g.dart';

/// Author metadata from Open Library's `/authors/{id}.json`. Lightweight by
/// design — Bulbul mostly shows author *names* (which arrive on the search doc),
/// but the model exists for the details flow and future author pages.
@JsonSerializable()
class Author extends Equatable {
  const Author({
    required this.key,
    required this.name,
    this.bio,
    this.birthDate,
    this.deathDate,
  });

  @JsonKey(fromJson: _idFromKey)
  final String key;

  final String name;

  @JsonKey(fromJson: _bioFromJson)
  final String? bio;

  @JsonKey(name: 'birth_date')
  final String? birthDate;

  @JsonKey(name: 'death_date')
  final String? deathDate;

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorToJson(this);

  @override
  List<Object?> get props => [key, name];
}

String _idFromKey(String key) =>
    key.startsWith('/authors/') ? key.substring('/authors/'.length) : key;

/// `bio` may be a plain string or a `{type, value}` typed-text object.
String? _bioFromJson(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map<String, dynamic>) return value['value'] as String?;
  return null;
}
