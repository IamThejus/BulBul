import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A reusable, cached book-cover image with graceful fallbacks. Covers are the
/// heaviest, most-repeated network asset in the app, so they go through
/// [CachedNetworkImage] (disk + memory cache). When no [imageUrl] exists, or it
/// fails to load, we render a tasteful monochrome placeholder built from the
/// book's [title] initials instead of a broken-image glyph.
class BookCoverImage extends StatelessWidget {
  const BookCoverImage({
    super.key,
    required this.imageUrl,
    this.title,
    this.width,
    this.height,
    this.borderRadius = AppConstants.radiusSm,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final String? title;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    return ClipRRect(
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: radius,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                width: width,
                height: height,
                fit: fit,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (_, _) => _Placeholder(width: width, height: height),
                errorWidget: (_, _, _) => _Fallback(
                  title: title,
                  width: width,
                  height: height,
                ),
              )
            : _Fallback(title: title, width: width, height: height),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.title, this.width, this.height});
  final String? title;
  final double? width;
  final double? height;

  String get _initials {
    final t = (title ?? '').trim();
    if (t.isEmpty) return '?';
    final words = t.split(RegExp(r'\s+'));
    if (words.length == 1) return words.first.characters.take(2).toString().toUpperCase();
    return (words[0].characters.first + words[1].characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.surface),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _initials,
                    style: AppTextStyles.headline.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.menu_book_outlined,
                      size: 16, color: AppColors.textTertiary.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
