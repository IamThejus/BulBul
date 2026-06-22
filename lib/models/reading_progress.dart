import 'package:hive/hive.dart';

/// Per-book reading position, persisted in Hive so the user can "continue
/// reading" across launches. We store everything needed to *resume without any
/// network metadata round-trip*: the content [format] + [contentUrl], the
/// current [chapterIndex] and [scrollFraction] within it, and a denormalized
/// title/author/cover for the Home "Continue Reading" cards.
///
/// We persist a *fraction* (0..1) within the chapter rather than a pixel offset
/// so positions survive font-size changes and different screen sizes.
class ReadingProgress {
  ReadingProgress({
    required this.id,
    required this.title,
    required this.author,
    this.coverUrl,
    required this.format, // 'epub' | 'html'
    required this.contentUrl,
    this.provider = 'gutenberg',
    this.chapterIndex = 0,
    this.scrollFraction = 0.0,
    this.totalChapters = 1,
    this.percent = 0.0,
    DateTime? lastReadAt,
  }) : lastReadAt = lastReadAt ?? DateTime.now();

  /// Canonical key: the Open Library work id when known, else `provider:id`.
  final String id;
  final String title;
  final String author;
  final String? coverUrl;
  final String format;
  final String contentUrl;
  final String provider;
  final int chapterIndex;
  final double scrollFraction;
  final int totalChapters;
  final double percent;
  final DateTime lastReadAt;

  bool get isEpub => format == 'epub';
  bool get isHtml => format == 'html';
  bool get isText => format == 'text';

  /// Whole-number reading percentage for display (e.g. `42`).
  int get percentLabel => (percent.clamp(0.0, 1.0) * 100).round();

  bool get isStarted => percent > 0.0;
  bool get isFinished => percent >= 0.99;

  ReadingProgress copyWith({
    String? title,
    String? author,
    String? coverUrl,
    int? chapterIndex,
    double? scrollFraction,
    int? totalChapters,
    double? percent,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      format: format,
      contentUrl: contentUrl,
      provider: provider,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      scrollFraction: scrollFraction ?? this.scrollFraction,
      totalChapters: totalChapters ?? this.totalChapters,
      percent: percent ?? this.percent,
      lastReadAt: lastReadAt ?? DateTime.now(),
    );
  }
}

/// Hive type adapter for [ReadingProgress]. `typeId` 2 is reserved here.
class ReadingProgressAdapter extends TypeAdapter<ReadingProgress> {
  @override
  final int typeId = 2;

  @override
  ReadingProgress read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ReadingProgress(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      coverUrl: fields[3] as String?,
      format: fields[4] as String,
      contentUrl: fields[5] as String,
      provider: fields[6] as String? ?? 'gutenberg',
      chapterIndex: fields[7] as int? ?? 0,
      scrollFraction: (fields[8] as num?)?.toDouble() ?? 0.0,
      totalChapters: fields[9] as int? ?? 1,
      percent: (fields[10] as num?)?.toDouble() ?? 0.0,
      lastReadAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ReadingProgress obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.coverUrl)
      ..writeByte(4)
      ..write(obj.format)
      ..writeByte(5)
      ..write(obj.contentUrl)
      ..writeByte(6)
      ..write(obj.provider)
      ..writeByte(7)
      ..write(obj.chapterIndex)
      ..writeByte(8)
      ..write(obj.scrollFraction)
      ..writeByte(9)
      ..write(obj.totalChapters)
      ..writeByte(10)
      ..write(obj.percent)
      ..writeByte(11)
      ..write(obj.lastReadAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressAdapter && other.typeId == typeId);
}
