import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/favorite_book.dart';
import '../services/favorites_service.dart';

/// Repository over local favorites. Thin by design — it exists so the feature
/// layer depends on an abstraction (`FavoritesRepository`) rather than directly
/// on Hive, keeping persistence swappable and testable.
class FavoritesRepository {
  FavoritesRepository(this._service);

  final FavoritesService _service;

  List<FavoriteBook> all() => _service.getAll();

  bool isFavorite(String workId) => _service.isFavorite(workId);

  Future<bool> toggle(FavoriteBook book) => _service.toggle(book);

  Future<void> remove(String workId) => _service.remove(workId);

  ValueListenable<Box<FavoriteBook>> listenable() => _service.listenable();
}
