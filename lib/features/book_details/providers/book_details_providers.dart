import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/book_details.dart';
import '../../../providers/app_providers.dart';

/// Fetches the full Open Library work record for the details screen, keyed by
/// work id. As a `family` it is automatically cached per book, so revisiting a
/// title doesn't refetch, and `ref.invalidate` gives us a clean retry.
final bookDetailsProvider =
    FutureProvider.family<BookDetails, String>((ref, workId) {
  return ref.watch(bookRepositoryProvider).details(workId);
});
