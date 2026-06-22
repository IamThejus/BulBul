import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../models/book_ref.dart';
import '../../../../models/favorite_book.dart';
import '../../../../models/reading_progress.dart';
import '../../../favorites/providers/favorites_providers.dart';
import '../../../reader/providers/reader_providers.dart';
import '../../providers/home_providers.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/home_favorite_card.dart';

/// The landing screen. Two horizontal rails — "Continue Reading" (reading
/// progress) and "Favorites" — over the pure-black canvas. When the user has
/// neither yet, a friendly empty state nudges them toward Search.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _openReader(BuildContext context, ReadingProgress p) {
    context.push(RoutePaths.reader, extra: ReaderArgs.resume(p));
  }

  void _openDetails(BuildContext context, FavoriteBook book) {
    context.push(
      RoutePaths.bookDetailsOf(book.workId),
      extra: BookRef.fromFavorite(book),
    );
  }

  Future<void> _confirmRemoveProgress(
    BuildContext context,
    WidgetRef ref,
    ReadingProgress p,
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
            Text(p.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.title),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('Remove from Continue Reading'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: AppConstants.spaceSm),
          ],
        ),
      ),
    );
    if (remove == true) {
      await ref.read(continueReadingProvider.notifier).remove(p.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueReading = ref.watch(continueReadingProvider);
    final favorites = ref.watch(favoritesProvider);
    final isEmpty = continueReading.isEmpty && favorites.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: isEmpty
            ? const _HomeEmptyState()
            : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _HomeHeader()),
                  if (continueReading.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: SectionHeader(
                        eyebrow: 'PICK UP WHERE YOU LEFT OFF',
                        title: 'Continue Reading',
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Rail(
                        height: 290,
                        itemCount: continueReading.length,
                        itemBuilder: (context, i) {
                          final p = continueReading[i];
                          return ContinueReadingCard(
                            progress: p,
                            onTap: () => _openReader(context, p),
                            onLongPress: () =>
                                _confirmRemoveProgress(context, ref, p),
                          );
                        },
                      ),
                    ),
                  ],
                  if (favorites.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: SectionHeader(
                        eyebrow: 'YOUR LIBRARY',
                        title: 'Favorites',
                        actionLabel: favorites.length > 3 ? 'See all' : null,
                        onActionTap: favorites.length > 3
                            ? () => context.go(RoutePaths.favorites)
                            : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Rail(
                        height: 270,
                        itemCount: favorites.length,
                        itemBuilder: (context, i) {
                          final f = favorites[i];
                          return HomeFavoriteCard(
                            book: f,
                            onTap: () => _openDetails(context, f),
                          );
                        },
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: AppConstants.spaceXl),
                  ),
                ],
              ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceLg,
        AppConstants.spaceMd,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Bulbul', style: AppTextStyles.display),
              const SizedBox(width: 8),
              // Nothing-OS-style single accent dot.
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Read freely.', style: AppTextStyles.body),
        ],
      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

/// Shared horizontal rail used by both home sections.
class _Rail extends StatelessWidget {
  const _Rail({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
  });

  final double height;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
        clipBehavior: Clip.none,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: AppConstants.spaceMd),
        itemBuilder: itemBuilder,
      ).animate().fadeIn(duration: 350.ms),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HomeHeader(),
        Expanded(
          child: AppEmptyView(
            icon: Icons.auto_stories_outlined,
            title: 'Your shelf is empty',
            subtitle:
                'Search for a book to start reading or add it to your favorites.',
            action: FilledButton.icon(
              onPressed: () => context.go(RoutePaths.search),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Find a book'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
