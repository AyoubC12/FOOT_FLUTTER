import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/preview/preview_catalog.dart';
import '../../../../core/preview/preview_models.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/prediction_bar.dart';
import '../../../../core/widgets/preview_banner.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_bar.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/team_crest.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class MatchDetailsScreen extends ConsumerWidget {
  const MatchDetailsScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = PreviewCatalog.matchById(matchId);
    final home = PreviewCatalog.teamById(match.homeId);
    final away = PreviewCatalog.teamById(match.awayId);
    final league = PreviewCatalog.leagueById(match.leagueId);
    final saved = ref.watch(favoritesProvider).matchIds.contains(match.id);
    final gutter = context.gutter();

    return Scaffold(
      appBar: AppBar(
        title: Text('${home.shortName} vs ${away.shortName}'),
        actions: [
          IconButton(
            tooltip: saved ? 'Remove favorite' : 'Save match',
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggleMatch(match.id),
            icon: Icon(
              saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: saved ? AppColors.accent : null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: PreviewBanner(label: 'Preview match sheet'),
          ),
          const SizedBox(height: 12),
          AppCard(
            accentBorder: true,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusBadge(status: match.status, minute: match.minute),
                    const SizedBox(width: 8),
                    Text(
                      league.name,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _ClubColumn(teamName: home.name, crest: home)),
                    Text(
                      match.homeScore == null
                          ? 'VS'
                          : '${match.homeScore} – ${match.awayScore}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Expanded(child: _ClubColumn(teamName: away.name, crest: away)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${match.venue} · ${match.kickoffLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Team statistics'),
          AppCard(
            child: Column(
              children: [
                StatBar.fromNumbers(
                  label: 'Possession %',
                  leftValue: match.stats.possessionHome,
                  rightValue: match.stats.possessionAway,
                ),
                StatBar.fromNumbers(
                  label: 'Shots',
                  leftValue: match.stats.shotsHome,
                  rightValue: match.stats.shotsAway,
                ),
                StatBar.fromNumbers(
                  label: 'Expected goals',
                  leftValue: match.stats.xgHome,
                  rightValue: match.stats.xgAway,
                ),
                StatBar.fromNumbers(
                  label: 'Corners',
                  leftValue: match.stats.cornersHome,
                  rightValue: match.stats.cornersAway,
                ),
                StatBar.fromNumbers(
                  label: 'Passes',
                  leftValue: match.stats.passesHome,
                  rightValue: match.stats.passesAway,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Head to head'),
          AppCard(
            child: Column(
              children: [
                for (final row in match.headToHead)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            row.label,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                        Text(
                          '${row.homeScore} – ${row.awayScore}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'AI prediction'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample model split — not a live market price.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                PredictionBar(match: match),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Ask FootGPT about this match',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => context.go(AppRoutes.chatbot),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClubColumn extends StatelessWidget {
  const _ClubColumn({required this.teamName, required this.crest});

  final String teamName;
  final PreviewTeam crest;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TeamCrest(team: crest, size: 64),
        const SizedBox(height: 8),
        Text(
          teamName,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
