import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/favorite_book.dart';
import '../models/reading_progress.dart';

/// Owns Hive initialization and box lifecycle. Call [init] exactly once during
/// app bootstrap (before `runApp`). Registering adapters and opening all boxes
/// up-front means the rest of the app can access boxes synchronously.
class HiveService {
  const HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();

    // Adapters are idempotent-guarded so hot-restart doesn't throw.
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FavoriteBookAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ReadingProgressAdapter());
    }

    await Future.wait([
      Hive.openBox<FavoriteBook>(AppConstants.favoritesBox),
      Hive.openBox<ReadingProgress>(AppConstants.progressBox),
      Hive.openBox<dynamic>(AppConstants.settingsBox),
    ]);
  }

  static Box<FavoriteBook> get favoritesBox =>
      Hive.box<FavoriteBook>(AppConstants.favoritesBox);

  static Box<ReadingProgress> get progressBox =>
      Hive.box<ReadingProgress>(AppConstants.progressBox);

  static Box<dynamic> get settingsBox =>
      Hive.box<dynamic>(AppConstants.settingsBox);
}
