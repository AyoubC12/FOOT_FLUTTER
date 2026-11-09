import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_catalog.dart';
import '../preview/preview_models.dart';
import 'app_card.dart';
import 'player_avatar.dart';

class PlayerTile extends StatelessWidget {
  const PlayerTile({
    super.key,
    required this.player,
    this.onTap,
    this.trailing,
  });

  final PreviewPlayer player;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final club = PreviewCatalog.teamById(player.clubId);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          PlayerAvatar(player: player, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.position} · ${club.name} · ${player.nationality}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          trailing ??
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    player.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${player.goals} G · ${player.assists} A',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
