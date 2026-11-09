import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_models.dart';

class PredictionBar extends StatelessWidget {
  const PredictionBar({super.key, required this.match});

  final PreviewMatch match;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: match.homeWinPct,
                  child: const ColoredBox(color: AppColors.accent),
                ),
                Expanded(
                  flex: match.drawPct,
                  child: const ColoredBox(color: AppColors.muted),
                ),
                Expanded(
                  flex: match.awayWinPct,
                  child: const ColoredBox(color: AppColors.info),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Home ${match.homeWinPct}%',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              'Draw ${match.drawPct}%',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            Text(
              'Away ${match.awayWinPct}%',
              style: const TextStyle(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
