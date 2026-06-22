import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../repositories/book_repository.dart';
import '../repositories/favorites_repository.dart';
import '../repositories/reading_repository.dart';
import '../services/favorites_service.dart';
import '../services/gutenberg_service.dart';
import '../services/hive_service.dart';
import '../services/internet_archive_service.dart';
import '../services/open_library_service.dart';
import '../services/reading_progress_service.dart';

/// The dependency-injection graph, expressed as Riverpod providers. Everything
/// downstream (feature providers, screens) resolves its collaborators from here,
/// which makes the whole app trivially overridable in tests via `ProviderScope`.

// --- Networking ---------------------------------------------------------------

final dioProvider = Provider<Dio>((ref) {
  final dio = DioClient.create();
  ref.onDispose(dio.close);
  return dio;
});

// --- Remote services ----------------------------------------------------------

final openLibraryServiceProvider = Provider<OpenLibraryService>(
  (ref) => OpenLibraryService(ref.watch(dioProvider)),
);

final gutenbergServiceProvider = Provider<GutenbergService>(
  (ref) => GutenbergService(ref.watch(dioProvider)),
);

final archiveServiceProvider = Provider<InternetArchiveService>(
  (ref) => InternetArchiveService(ref.watch(dioProvider)),
);

// --- Local services (Hive-backed) --------------------------------------------

final favoritesServiceProvider = Provider<FavoritesService>(
  (ref) => FavoritesService(HiveService.favoritesBox),
);

final progressServiceProvider = Provider<ReadingProgressService>(
  (ref) => ReadingProgressService(HiveService.progressBox),
);

// --- Repositories -------------------------------------------------------------

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(ref.watch(openLibraryServiceProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(favoritesServiceProvider)),
);

final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => ReadingRepository(
    dio: ref.watch(dioProvider),
    gutenberg: ref.watch(gutenbergServiceProvider),
    archive: ref.watch(archiveServiceProvider),
    progress: ref.watch(progressServiceProvider),
  ),
);
