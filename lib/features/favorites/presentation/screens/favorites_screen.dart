import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../models/book_ref.dart';
import '../../../../models/favorite_book.dart';
import '../../providers/favorites_providers.dart';

/// A grid of the user's favorited books, persisted in Hive. Tap opens details;
/// long-press offers removal. Fully offline — everything comes from local store.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  void _openDetails(BuildContext context, FavoriteBook book) {
    context.push(
      RoutePaths.bookDetailsOf(book.workId),
      extra: BookRef.fromFavorite(book),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    FavoriteBook book,
  ) async {
    final remove = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppConstants.spaceMd),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.heart_broken_outlined),
              title: const Text('Remove from Favorites'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppConstants.spaceSm),
          ],
        ),
      ),
    );
    if (remove == true) {
      await ref.read(favoritesProvider.notifier).remove(book.workId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppConstants.spaceMd,
                  AppConstants.spaceLg,
                  AppConstants.spaceMd,
                  AppConstants.spaceMd,
                ),
                child: Text('Favorites', style: AppTextStyles.display),
              ),
            ),
            if (favorites.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyView(
                  icon: Icons.favorite_border_rounded,
                  title: 'No favorites yet',
                  subtitle:
                      'Tap the heart on any book to keep it here for later.',
                  action: FilledButton.icon(
                    onPressed: () => context.go(RoutePaths.search),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Find a book'),
                    style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceMd,
                  0,
                  AppConstants.spaceMd,
                  AppConstants.spaceXl,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.52,
                    crossAxisSpacing: AppConstants.spaceMd,
                    mainAxisSpacing: AppConstants.spaceLg,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = favorites[index];
                      return _FavoriteTile(
                        book: book,
                        onTap: () => _openDetails(context, book),
                        onLongPress: () => _confirmRemove(context, ref, book),
                      );
                    },
                    childCount: favorites.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.book,
    required this.onTap,
    required this.onLongPress,
  });

  final FavoriteBook book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: BookCoverImage(imageUrl: book.coverUrl, title: book.title),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}
