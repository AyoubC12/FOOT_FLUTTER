import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../preview/preview_catalog.dart';
import '../preview/preview_models.dart';
import 'app_card.dart';
import 'status_badge.dart';
import 'team_crest.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.compact = false,
  });

  final PreviewMatch match;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final home = PreviewCatalog.teamById(match.homeId);
    final away = PreviewCatalog.teamById(match.awayId);
    final league = PreviewCatalog.leagueById(match.leagueId);
    final showScore = match.status != PreviewMatchStatus.upcoming;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 12 : 16),
      accentBorder: match.status == PreviewMatchStatus.live,
      child: Column(
        children: [
          Row(
            children: [
              StatusBadge(status: match.status, minute: match.minute),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  league.name,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
              ),
              Text(
                match.kickoffLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          Row(
            children: [
              Expanded(child: _TeamBlock(team: home, compact: compact)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: showScore
                    ? Text(
                        '${match.homeScore}  –  ${match.awayScore}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      )
                    : Text(
                        'VS',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
              ),
              Expanded(child: _TeamBlock(team: away, compact: compact)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({required this.team, required this.compact});

  final PreviewTeam team;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamCrest(team: team, size: compact ? 40 : 52),
        const SizedBox(height: 8),
        Text(
          team.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
