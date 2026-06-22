import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/favorite_book.dart';

/// Repository-style wrapper over the favorites Hive box. The box is keyed by
/// `workId`, which gives O(1) membership checks and natural de-duplication
/// (re-favoriting just overwrites). All reads are local, so Favorites work
/// fully offline and persist across launches.
class FavoritesService {
  FavoritesService(this._box);

  final Box<FavoriteBook> _box;

  /// All favorites, newest-added first.
  List<FavoriteBook> getAll() {
    final items = _box.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return items;
  }

  bool isFavorite(String workId) => _box.containsKey(workId);

  Future<void> add(FavoriteBook book) => _box.put(book.workId, book);

  Future<void> remove(String workId) => _box.delete(workId);

  /// Adds if absent, removes if present. Returns the resulting state
  /// (`true` == now a favorite) so the caller can update UI/snackbars.
  Future<bool> toggle(FavoriteBook book) async {
    if (isFavorite(book.workId)) {
      await remove(book.workId);
      return false;
    }
    await add(book);
    return true;
  }

  /// Reactive handle used by Hive's `ValueListenableBuilder` and by our
  /// Riverpod notifier to rebuild when favorites change.
  ValueListenable<Box<FavoriteBook>> listenable() => _box.listenable();
}
