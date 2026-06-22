import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/favorite_book.dart';
import '../../../providers/app_providers.dart';

/// Reactive favorites state. All favorite mutations route through this notifier
/// so every surface (Home, Favorites, Details) stays in sync. It also subscribes
/// to the underlying Hive box, so changes made elsewhere still refresh the list.
class FavoritesNotifier extends Notifier<List<FavoriteBook>> {
  @override
  List<FavoriteBook> build() {
    final repo = ref.watch(favoritesRepositoryProvider);
    final listenable = repo.listenable();

    void sync() => state = repo.all();
    listenable.addListener(sync);
    ref.onDispose(() => listenable.removeListener(sync));

    return repo.all();
  }

  /// Toggles favorite status; returns `true` if the book is now a favorite.
  Future<bool> toggle(FavoriteBook book) async {
    final result = await ref.read(favoritesRepositoryProvider).toggle(book);
    state = ref.read(favoritesRepositoryProvider).all();
    return result;
  }

  Future<void> remove(String workId) async {
    await ref.read(favoritesRepositoryProvider).remove(workId);
    state = ref.read(favoritesRepositoryProvider).all();
  }

  bool isFavorite(String workId) => state.any((b) => b.workId == workId);
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<FavoriteBook>>(
  FavoritesNotifier.new,
);

/// Convenience selector used by the details screen to react to a single book's
/// favorite status without rebuilding on unrelated favorites changes.
final isFavoriteProvider = Provider.family<bool, String>((ref, workId) {
  final favorites = ref.watch(favoritesProvider);
  return favorites.any((b) => b.workId == workId);
});
