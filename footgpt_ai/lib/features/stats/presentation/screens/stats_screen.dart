import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/football/featured_clubs.dart';
import '../../../../core/football/football_seasons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/club_logo.dart';
import '../../../../core/widgets/data_notice.dart';
import '../../../../core/widgets/history_chart.dart';
import '../../../../core/widgets/season_selector.dart';
import '../../../teams/domain/team_models.dart';
import '../../../teams/presentation/providers/teams_providers.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  FeaturedClub _club = FeaturedClubs.clubs.first;
  int _season = FootballSeasons.currentStartYear;

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    final history = ref.watch(
      teamSeasonsProvider(
        TeamHistoryLookup(teamId: _club.id, leagueId: _club.leagueId),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Historical statistics')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
        children: [
          Text(
            'Seasons ${FootballSeasons.label(FootballSeasons.firstYear)} through ${FootballSeasons.label(FootballSeasons.lastYear)}. Current campaigns are labelled and never marked complete.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 86,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FeaturedClubs.clubs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final club = FeaturedClubs.clubs[index];
                final selected = club.id == _club.id;
                return AppCard(
                  accentBorder: selected,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () => setState(() => _club = club),
                  child: SizedBox(
                    width: 86,
                    child: Column(
                      children: [
                        ClubLogo(name: club.name, url: club.logo, size: 36),
                        const SizedBox(height: 6),
                        Text(
                          club.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.accent : AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SeasonSelector(
            value: _season,
            fullHistory: true,
            onChanged: (year) => setState(() => _season = year),
          ),
          const SizedBox(height: 16),
          AppCard(
            accentBorder: true,
            child: Row(
              children: [
                ClubLogo(name: _club.name, url: _club.logo, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _club.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_club.league} · ${FootballSeasons.label(_season)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      if (!FootballSeasons.isComplete(_season))
                        const Text(
                          'Current season — not marked complete',
                          style: TextStyle(color: AppColors.accent, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (AppConstants.apiBaseUrl.isEmpty)
            const DataNotice(
              message:
                  'Historical tables, shots, possession and player season stats require Django + API-Football. Nothing is fabricated here.',
            )
          else
            history.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => DataNotice(
                message: error is ApiException
                    ? error.message
                    : 'Season history is unavailable until the club is synced.',
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const DataNotice(
                    message:
                        'No verified season rows are stored yet. Open this club after a catalog sync.',
                  );
                }
                final selected = rows.where((row) => row.year == _season).toList();
                final points = [
                  for (final row in rows.reversed)
                    if (row.points != null) SeasonPoint(year: row.year, value: row.points!),
                ];
                final goals = [
                  for (final row in rows.reversed)
                    if (row.goalsFor != null)
                      SeasonPoint(year: row.year, value: row.goalsFor!),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Points', style: TextStyle(color: AppColors.muted)),
                    HistoryChart(points: points),
                    const SizedBox(height: 12),
                    const Text('Goals scored', style: TextStyle(color: AppColors.muted)),
                    HistoryChart(points: goals),
                    const SizedBox(height: 16),
                    if (selected.isEmpty)
                      DataNotice(
                        message:
                            'No stored statistics for ${FootballSeasons.label(_season)}.',
                      )
                    else
                      for (final row in selected) _SeasonStatsCard(row: row),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _SeasonStatsCard extends StatelessWidget {
  const _SeasonStatsCard({required this.row});

  final TeamSeasonRow row;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row.label} · ${row.competitionName ?? 'Competition'}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          Text(
            row.isComplete ? 'Completed season' : 'In progress — not marked complete',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatChip('Played', row.played),
              _StatChip('Wins', row.wins),
              _StatChip('Draws', row.draws),
              _StatChip('Losses', row.losses),
              _StatChip('GF', row.goalsFor),
              _StatChip('GA', row.goalsAgainst),
              _StatChip('Points', row.points),
              _StatChip('Position', row.rank),
              _StatChip('Clean sheets', row.cleanSheets),
              _StatChip('Possession', row.possessionAvg, suffix: '%'),
              _StatChip('Shots / game', row.shotsPerGame),
            ],
          ),
          if (row.missingFields.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Unavailable: ${row.missingFields.join(', ')}',
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value, {this.suffix = ''});

  final String label;
  final num? value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          Text(
            value == null ? '—' : '$value$suffix',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
