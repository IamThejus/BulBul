import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../theme/app_text_styles.dart';

/// A consistent home-screen section header: a small uppercase eyebrow over a
/// larger title, with an optional trailing action (e.g. "See all"). Using one
/// widget keeps every section visually aligned.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.onActionTap,
    this.actionLabel,
  });

  final String eyebrow;
  final String title;
  final VoidCallback? onActionTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceLg,
        AppConstants.spaceMd,
        AppConstants.spaceSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow, style: AppTextStyles.eyebrow),
                const SizedBox(height: 4),
                Text(title, style: AppTextStyles.headline),
              ],
            ),
          ),
          if (onActionTap != null && actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel!, style: AppTextStyles.caption),
            ),
        ],
      ),
    );
  }
}
