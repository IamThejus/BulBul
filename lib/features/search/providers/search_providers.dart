import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/failure.dart';
import '../../../models/book.dart';
import '../../../providers/app_providers.dart';

enum SearchStatus { idle, loading, success, loadingMore, error }

/// Immutable snapshot of the search screen. Carrying the active [query] lets the
/// notifier discard out-of-order (stale) responses, and [numFound] vs the loaded
/// [books] count drives pagination.
class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.books = const [],
    this.numFound = 0,
    this.page = 1,
    this.failure,
  });

  final SearchStatus status;
  final String query;
  final List<Book> books;
  final int numFound;
  final int page;
  final Failure? failure;

  bool get hasMore => books.length < numFound;
  bool get isIdle => status == SearchStatus.idle;
  bool get isEmpty => status == SearchStatus.success && books.isEmpty;

  static const Object _keep = Object();

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Book>? books,
    int? numFound,
    int? page,
    Object? failure = _keep,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      books: books ?? this.books,
      numFound: numFound ?? this.numFound,
      page: page ?? this.page,
      failure: identical(failure, _keep) ? this.failure : failure as Failure?,
    );
  }

  @override
  List<Object?> get props => [status, query, books, numFound, page, failure];
}

/// Drives search + pagination. The screen debounces keystrokes and calls
/// [search]; out-of-order responses are dropped by comparing against the latest
/// [SearchState.query]. [loadMore] appends the next page for lazy/infinite lists.
class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(
      status: SearchStatus.loading,
      query: query,
      books: const [],
      page: 1,
      failure: null,
    );

    try {
      final result = await ref
          .read(bookRepositoryProvider)
          .search(query, page: 1, limit: AppConstants.searchPageSize);

      if (state.query != query) return; // a newer query superseded us
      state = state.copyWith(
        status: SearchStatus.success,
        books: result.books,
        numFound: result.numFound,
        page: 1,
      );
    } catch (e) {
      if (state.query != query) return;
      state = state.copyWith(status: SearchStatus.error, failure: Failure.from(e));
    }
  }

  Future<void> loadMore() async {
    if (state.status == SearchStatus.loadingMore || !state.hasMore) return;
    final nextPage = state.page + 1;
    final query = state.query;

    state = state.copyWith(status: SearchStatus.loadingMore);
    try {
      final result = await ref
          .read(bookRepositoryProvider)
          .search(query, page: nextPage, limit: AppConstants.searchPageSize);

      if (state.query != query) return;
      state = state.copyWith(
        status: SearchStatus.success,
        books: [...state.books, ...result.books],
        numFound: result.numFound,
        page: nextPage,
      );
    } catch (_) {
      // Keep what we have; a failed "load more" shouldn't wipe results.
      if (state.query == query) {
        state = state.copyWith(status: SearchStatus.success);
      }
    }
  }

  void clear() => state = const SearchState();
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
