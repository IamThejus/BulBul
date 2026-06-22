import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/book_cover_image.dart';
import '../../../../models/reading_progress.dart';

/// Home "Continue Reading" card: cover + title + a slim progress bar and
/// percentage. Long-press surfaces a remove action (handled by the parent).
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.progress,
    required this.onTap,
    this.onLongPress,
  });

  final ReadingProgress progress;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCoverImage(
              imageUrl: progress.coverUrl,
              title: progress.title,
              width: 150,
              height: 210,
            ),
            const SizedBox(height: 10),
            Text(
              progress.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress.percent.clamp(0.0, 1.0),
                      minHeight: 3,
                      backgroundColor: AppColors.surfaceHigh,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${progress.percentLabel}%', style: AppTextStyles.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
