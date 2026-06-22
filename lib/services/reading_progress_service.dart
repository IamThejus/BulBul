import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/reading_progress.dart';

/// Local store for reading positions, keyed by [ReadingProgress.id]. Powers the
/// Home "Continue Reading" rail and the reader's resume-on-open behaviour.
class ReadingProgressService {
  ReadingProgressService(this._box);

  final Box<ReadingProgress> _box;

  /// Books that are started but not finished, most-recently-read first — exactly
  /// what the "Continue Reading" section wants.
  List<ReadingProgress> getContinueReading() {
    final items = _box.values
        .where((p) => p.isStarted && !p.isFinished)
        .toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return items;
  }

  List<ReadingProgress> getAll() {
    final items = _box.values.toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
    return items;
  }

  ReadingProgress? get(String id) => _box.get(id);

  Future<void> save(ReadingProgress progress) => _box.put(progress.id, progress);

  Future<void> remove(String id) => _box.delete(id);

  ValueListenable<Box<ReadingProgress>> listenable() => _box.listenable();
}
