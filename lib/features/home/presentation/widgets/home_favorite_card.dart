import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../models/favorite_book.dart';

/// Home "Favorites" card: a cover with title + author beneath. Tapping opens the
/// details screen.
class HomeFavoriteCard extends StatelessWidget {
  const HomeFavoriteCard({super.key, required this.book, required this.onTap});

  final FavoriteBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCoverImage(
              imageUrl: book.coverUrl,
              title: book.title,
              width: 130,
              height: 190,
            ),
            const SizedBox(height: 10),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(fontSize: 14, height: 1.2),
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
