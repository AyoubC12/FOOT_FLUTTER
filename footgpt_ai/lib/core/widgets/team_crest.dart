import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_models.dart';

class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.team, this.size = 48});

  final PreviewTeam team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final onColor = team.color.computeLuminance() > 0.6
        ? AppColors.background
        : AppColors.white;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: team.color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: team.color.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        team.shortName.substring(0, team.shortName.length.clamp(0, 3)),
        style: TextStyle(
          color: onColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.26,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
