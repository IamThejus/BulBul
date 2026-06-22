import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/debouncer.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../models/book.dart';
import '../../../../models/book_ref.dart';
import '../../providers/search_providers.dart';
import '../widgets/search_result_tile.dart';

/// Search with debounced, as-you-type results that double as autocomplete
/// suggestions (Spotify-style). Scrolling near the bottom lazily loads the next
/// page. All async states (idle / loading / empty / error) are handled.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _debouncer = Debouncer(delay: AppConstants.searchDebounce);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // refresh the clear-button affordance
    _debouncer.run(() {
      if (!mounted) return;
      ref.read(searchProvider.notifier).search(value);
    });
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _clear() {
    _controller.clear();
    _debouncer.cancel();
    ref.read(searchProvider.notifier).clear();
    setState(() {});
  }

  void _openDetails(Book book) {
    FocusScope.of(context).unfocus();
    context.push(
      RoutePaths.bookDetailsOf(book.workId),
      extra: BookRef.fromBook(book),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceMd,
                AppConstants.spaceLg,
                AppConstants.spaceMd,
                AppConstants.spaceMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search', style: AppTextStyles.display),
                  const SizedBox(height: AppConstants.spaceMd),
                  _SearchField(
                    controller: _controller,
                    onChanged: _onChanged,
                    onClear: _clear,
                    hasText: _controller.text.isNotEmpty,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _Results(
                state: state,
                onTap: _openDetails,
                controller: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.hasText,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool hasText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          const SizedBox(width: AppConstants.spaceSm),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              autocorrect: false,
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w400),
              cursorColor: AppColors.white,
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: AppConstants.spaceMd),
                border: InputBorder.none,
                hintText: 'Books, authors…',
                hintStyle: AppTextStyles.title.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (hasText)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({
    required this.state,
    required this.onTap,
    required this.controller,
  });

  final SearchState state;
  final void Function(Book) onTap;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case SearchStatus.idle:
        return const AppEmptyView(
          icon: Icons.menu_book_rounded,
          title: 'Discover your next read',
          subtitle: 'Search millions of books by title or author.',
        );
      case SearchStatus.loading:
        return const AppLoadingView();
      case SearchStatus.error:
        return AppErrorView(
          failure: state.failure!,
          onRetry: () {}, // retry handled by re-typing; kept for offline UX
        );
      case SearchStatus.success:
      case SearchStatus.loadingMore:
        if (state.books.isEmpty) {
          return AppEmptyView(
            icon: Icons.search_off_rounded,
            title: 'No results for "${state.query}"',
            subtitle: 'Try a different title or author.',
          );
        }
        return _ResultsList(state: state, onTap: onTap, controller: controller);
    }
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.state,
    required this.onTap,
    required this.controller,
  });

  final SearchState state;
  final void Function(Book) onTap;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final showFooter = state.status == SearchStatus.loadingMore;
    return ListView.separated(
      controller: controller,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: AppConstants.spaceXl),
      itemCount: state.books.length + (showFooter ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(indent: 76),
      itemBuilder: (context, index) {
        if (index >= state.books.length) {
          return const Padding(
            padding: EdgeInsets.all(AppConstants.spaceMd),
            child: Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final book = state.books[index];
        return SearchResultTile(book: book, onTap: () => onTap(book));
      },
    );
  }
}
