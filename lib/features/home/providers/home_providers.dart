import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/reading_progress.dart';
import '../../../providers/app_providers.dart';

/// Reactive "Continue Reading" list — books that are started but not finished,
/// most-recently-read first. Backed by the reading-progress Hive box, so it
/// updates the instant the reader saves a new position.
class ContinueReadingNotifier extends Notifier<List<ReadingProgress>> {
  @override
  List<ReadingProgress> build() {
    final repo = ref.watch(readingRepositoryProvider);
    final listenable = repo.progressListenable();

    void sync() => state = repo.continueReading();
    listenable.addListener(sync);
    ref.onDispose(() => listenable.removeListener(sync));

    return repo.continueReading();
  }

  /// Lets the user dismiss a book from the rail (deletes its saved progress).
  Future<void> remove(String id) async {
    await ref.read(readingRepositoryProvider).removeProgress(id);
    state = ref.read(readingRepositoryProvider).continueReading();
  }
}

final continueReadingProvider =
    NotifierProvider<ContinueReadingNotifier, List<ReadingProgress>>(
  ContinueReadingNotifier.new,
);
