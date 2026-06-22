import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../models/book_details.dart';
import '../../../../models/book_ref.dart';
import '../../../../models/favorite_book.dart';
import '../../../favorites/providers/favorites_providers.dart';
import '../../../reader/providers/reader_providers.dart';
import '../../providers/book_details_providers.dart';

/// Full-screen book details. Renders its header *instantly* from the [initial]
/// [BookRef] (passed during navigation) while the full Open Library work record
/// streams in for description/subjects. A sticky bottom bar hosts the primary
/// actions: Read Now + favorite toggle.
class BookDetailsScreen extends ConsumerWidget {
  const BookDetailsScreen({super.key, required this.workId, this.initial});

  final String workId;
  final BookRef? initial;

  String _title(BookDetails? d) => initial?.title ?? d?.title ?? 'Book';
  String _author(BookDetails? d) =>
      initial?.author ?? (d == null ? '' : 'Unknown author');
  String? _cover(BookDetails? d) => initial?.coverUrl ?? d?.coverUrl;

  int? _year(BookDetails? d) {
    if (initial?.firstPublishYear != null) return initial!.firstPublishYear;
    final raw = d?.firstPublishDate;
    if (raw == null) return null;
    final match = RegExp(r'\d{4}').firstMatch(raw);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  void _read(BuildContext context, BookDetails? d) {
    context.push(
      RoutePaths.reader,
      extra: ReaderArgs(
        id: workId,
        title: _title(d),
        author: _author(d),
        coverUrl: _cover(d),
        iaIdentifiers: initial?.iaIdentifiers ?? const [],
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    BookDetails? d,
  ) async {
    final favorite = initial?.toFavorite() ??
        FavoriteBook(
          workId: workId,
          title: _title(d),
          author: _author(d),
          coverUrl: _cover(d),
          firstPublishYear: _year(d),
        );

    final nowFavorite =
        await ref.read(favoritesProvider.notifier).toggle(favorite);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            nowFavorite ? 'Added to Favorites' : 'Removed from Favorites',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(bookDetailsProvider(workId));
    final isFavorite = ref.watch(isFavoriteProvider(workId));
    final details = detailsAsync.value;

    // If we have neither an initial ref nor loaded details, show full-screen
    // loading/error so the user isn't staring at an empty header.
    if (initial == null && !detailsAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: detailsAsync.isLoading
            ? const AppLoadingView()
            : AppErrorView(
                failure: Failure.from(detailsAsync.error ?? 'Unknown error'),
                onRetry: () => ref.invalidate(bookDetailsProvider(workId)),
              ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.black,
            surfaceTintColor: Colors.transparent,
            leading: const BackButton(),
            title: Text(
              _title(details),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title,
            ),
          ),
          SliverToBoxAdapter(
            child: _Header(
              title: _title(details),
              author: _author(details),
              coverUrl: _cover(details),
              year: _year(details),
              pageCount: initial?.pageCount,
            ),
          ),
          SliverToBoxAdapter(
            child: _DescriptionSection(
              detailsAsync: detailsAsync,
              onRetry: () => ref.invalidate(bookDetailsProvider(workId)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        isFavorite: isFavorite,
        onRead: () => _read(context, details),
        onToggleFavorite: () => _toggleFavorite(context, ref, details),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.year,
    required this.pageCount,
  });

  final String title;
  final String author;
  final String? coverUrl;
  final int? year;
  final int? pageCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceMd,
        AppConstants.spaceLg,
        AppConstants.spaceLg,
      ),
      child: Column(
        children: [
          Center(
            child: BookCoverImage(
              imageUrl: coverUrl,
              title: title,
              width: 180,
              height: 260,
              borderRadius: AppConstants.radius,
            ),
          ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.96, end: 1),
          const SizedBox(height: AppConstants.spaceLg),
          Text(title, style: AppTextStyles.headline, textAlign: TextAlign.center),
          const SizedBox(height: AppConstants.spaceSm),
          Text(author, style: AppTextStyles.body, textAlign: TextAlign.center),
          if (year != null || pageCount != null) ...[
            const SizedBox(height: AppConstants.spaceMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (year != null) _MetaChip(Icons.event_outlined, '$year'),
                if (year != null && pageCount != null)
                  const SizedBox(width: AppConstants.spaceSm),
                if (pageCount != null)
                  _MetaChip(Icons.menu_book_outlined, '$pageCount pages'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd, vertical: AppConstants.spaceSm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  const _DescriptionSection({required this.detailsAsync, required this.onRetry});

  final AsyncValue<BookDetails> detailsAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: AppConstants.spaceMd),
          Text('About', style: AppTextStyles.title),
          const SizedBox(height: AppConstants.spaceMd),
          detailsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppConstants.spaceLg),
              child: AppLoadingView(),
            ),
            error: (_, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceMd),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Couldn't load the description.",
                      style: AppTextStyles.body,
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
            data: (details) => _DescriptionBody(details: details),
          ),
        ],
      ),
    );
  }
}

class _DescriptionBody extends StatelessWidget {
  const _DescriptionBody({required this.details});
  final BookDetails details;

  @override
  Widget build(BuildContext context) {
    final subjects = details.subjects.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (details.description?.isNotEmpty ?? false)
              ? details.description!
              : 'No description is available for this book yet.',
          style: AppTextStyles.body.copyWith(height: 1.65),
        ),
        if (subjects.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spaceLg),
          Text('Subjects', style: AppTextStyles.title),
          const SizedBox(height: AppConstants.spaceMd),
          Wrap(
            spacing: AppConstants.spaceSm,
            runSpacing: AppConstants.spaceSm,
            children: [
              for (final s in subjects)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spaceMd, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(s, style: AppTextStyles.caption),
                ),
            ],
          ),
        ],
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isFavorite,
    required this.onRead,
    required this.onToggleFavorite,
  });

  final bool isFavorite;
  final VoidCallback onRead;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.black,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.all(AppConstants.spaceMd),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onRead,
                icon: const Icon(Icons.menu_book_rounded, size: 20),
                label: const Text('Read Now'),
              ),
            ),
            const SizedBox(width: AppConstants.spaceMd),
            _FavoriteButton(isFavorite: isFavorite, onTap: onToggleFavorite),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(54, 54),
          side: BorderSide(
            color: isFavorite ? AppColors.white : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: AppColors.white,
          size: 22,
        ),
      ),
    );
  }
}
