import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../tactics/pitch_player.dart';

class PitchToken extends StatelessWidget {
  const PitchToken({
    super.key,
    required this.player,
    this.selected = false,
    this.compact = false,
  });

  final PitchPlayer player;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 42.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C3A2C), AppColors.surfaceElevated],
            ),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 2.4 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            player.number?.toString() ?? player.initials,
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${player.lastName} · ${player.position}',
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
