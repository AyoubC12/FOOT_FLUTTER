import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_catalog.dart';
import '../preview/preview_models.dart';

class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.player, this.size = 64});

  final PreviewPlayer player;
  final double size;

  @override
  Widget build(BuildContext context) {
    final club = PreviewCatalog.teamById(player.clubId);
    final initials = player.initials;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [club.color, AppColors.surfaceElevated],
              ),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: size * 0.28,
                color: AppColors.white,
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${player.number}',
                style: TextStyle(
                  color: AppColors.background,
                  fontSize: size * 0.16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
