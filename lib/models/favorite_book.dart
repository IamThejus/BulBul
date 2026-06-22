import 'package:hive/hive.dart';

import 'book.dart';

/// A book the user has favorited, persisted in Hive. We store a denormalized
/// snapshot (title/author/cover) so Favorites and Home render instantly and
/// fully offline — no re-fetch from Open Library required.
///
/// NOTE: the [FavoriteBookAdapter] below is written by hand (rather than via
/// `hive_generator`) because that generator pins an old `source_gen` that
/// conflicts with modern `json_serializable`. The binary layout intentionally
/// mirrors what the generator emits, so it stays forward-compatible.
class FavoriteBook {
  FavoriteBook({
    required this.workId,
    required this.title,
    required this.author,
    this.coverUrl,
    this.firstPublishYear,
    this.iaIdentifier,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  final String workId;
  final String title;
  final String author;
  final String? coverUrl;
  final int? firstPublishYear;

  /// First Internet Archive id (if any) — lets us offer a reading fallback.
  final String? iaIdentifier;
  final DateTime addedAt;

  factory FavoriteBook.fromBook(Book book) => FavoriteBook(
        workId: book.workId,
        title: book.title,
        author: book.authorLabel,
        coverUrl: book.coverUrl,
        firstPublishYear: book.firstPublishYear,
        iaIdentifier:
            book.iaIdentifiers.isNotEmpty ? book.iaIdentifiers.first : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteBook && other.workId == workId);

  @override
  int get hashCode => workId.hashCode;
}

/// Hive type adapter for [FavoriteBook]. `typeId` 1 is reserved for this model.
class FavoriteBookAdapter extends TypeAdapter<FavoriteBook> {
  @override
  final int typeId = 1;

  @override
  FavoriteBook read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return FavoriteBook(
      workId: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      coverUrl: fields[3] as String?,
      firstPublishYear: fields[4] as int?,
      iaIdentifier: fields[5] as String?,
      addedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FavoriteBook obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.workId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.coverUrl)
      ..writeByte(4)
      ..write(obj.firstPublishYear)
      ..writeByte(5)
      ..write(obj.iaIdentifier)
      ..writeByte(6)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoriteBookAdapter && other.typeId == typeId);
}
