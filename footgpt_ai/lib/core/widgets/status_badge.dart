import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.minute});

  final PreviewMatchStatus status;
  final int? minute;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PreviewMatchStatus.live => ('LIVE ${minute ?? ''}’', AppColors.danger),
      PreviewMatchStatus.upcoming => ('UPCOMING', AppColors.info),
      PreviewMatchStatus.finished => ('FT', AppColors.muted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
