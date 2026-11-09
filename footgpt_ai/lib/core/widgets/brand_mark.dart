import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.showWordmark = false});

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C3312), Color(0xFF111A2B)],
        ),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.18),
            blurRadius: 16,
          ),
        ],
      ),
      child: Icon(
        Icons.sports_soccer_rounded,
        color: AppColors.accent,
        size: size * 0.54,
      ),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FootGPT AI',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Match intelligence',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
