import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/club_logo.dart';
import '../../../../core/widgets/history_chart.dart';
import '../../../../core/widgets/player_photo.dart';
import '../../../../core/widgets/section_header.dart';
import '../providers/teams_providers.dart';

class TeamDetailsScreen extends ConsumerWidget {
  const TeamDetailsScreen({super.key, required this.teamId, this.leagueId});

  final String teamId;
  final String? leagueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(teamId);
    final gutter = context.gutter();
    if (id == null) {
      return const Scaffold(
        body: AppErrorView(message: 'This club is not linked to an API-Football team id.'),
      );
    }
    final detail = ref.watch(teamDetailProvider(id));
    final seasons = ref.watch(
      teamSeasonsProvider(
        TeamHistoryLookup(teamId: id, leagueId: int.tryParse(leagueId ?? '')),
      ),
    );
    final squad = ref.watch(teamSquadProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text(detail.asData?.value.name ?? 'Club')),
      body: detail.when(
        loading: () => const AppLoader(message: 'Loading club…'),
        error: (error, _) => AppErrorView(
          message: error is ApiException ? error.message : 'Could not load this club.',
          onRetry: () => ref.invalidate(teamDetailProvider(id)),
        ),
        data: (club) => ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
          children: [
            AppCard(
              child: Row(
                children: [
                  ClubLogo(name: club.name, url: club.logo, size: 72),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          [
                            if (club.founded != null) 'Founded ${club.founded}',
                            club.city,
                            club.country,
                          ].whereType<String>().where((part) => part.isNotEmpty).join(' · '),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Info('Stadium', club.stadiumName),
                  _Info('Capacity', club.stadiumCapacity?.toString()),
                  _Info('Coach', club.coachName),
                  _Info('Website', club.website),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Season history'),
            seasons.when(
              loading: () => const AppLoader(message: 'Loading stored seasons…'),
              error: (error, _) => Text(
                error is ApiException ? error.message : 'Season history unavailable.',
                style: const TextStyle(color: AppColors.muted),
              ),
              data: (rows) {
                if (rows.isEmpty) {
                  return const Text(
                    'No stored season statistics yet. Open standings for a league/season or run sync_football_catalog.',
                    style: TextStyle(color: AppColors.muted),
                  );
                }
                final points = [
                  for (final row in rows.reversed)
                    if (row.points != null) SeasonPoint(year: row.year, value: row.points!),
                ];
                final wins = [
                  for (final row in rows.reversed)
                    if (row.wins != null) SeasonPoint(year: row.year, value: row.wins!),
                ];
                final ranks = [
                  for (final row in rows.reversed)
                    if (row.rank != null) SeasonPoint(year: row.year, value: row.rank!),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Points', style: TextStyle(color: AppColors.muted)),
                    HistoryChart(points: points),
                    const SizedBox(height: 12),
                    const Text('Wins', style: TextStyle(color: AppColors.muted)),
                    HistoryChart(points: wins),
                    const SizedBox(height: 12),
                    const Text('League rank (lower is better)', style: TextStyle(color: AppColors.muted)),
                    HistoryChart(points: ranks, invertY: true),
                    const SizedBox(height: 12),
                    for (final row in rows)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${row.label} · ${row.competitionName ?? 'Competition'}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                row.isComplete
                                    ? 'Completed season'
                                    : 'In progress — not marked complete',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                              Text(
                                [
                                  if (row.rank != null) 'P${row.rank}',
                                  if (row.points != null) '${row.points} pts',
                                  if (row.played != null) '${row.played} played',
                                  if (row.wins != null) '${row.wins} W',
                                ].join(' · '),
                              ),
                              if (row.missingFields.isNotEmpty)
                                Text(
                                  'Unavailable: ${row.missingFields.join(', ')}',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Squad'),
            squad.when(
              loading: () => const AppLoader(message: 'Loading squad…'),
              error: (_, _) => const Text(
                'Squad has not been stored yet.',
                style: TextStyle(color: AppColors.muted),
              ),
              data: (players) {
                if (players.isEmpty) {
                  return const Text(
                    'No squad players stored for this club yet.',
                    style: TextStyle(color: AppColors.muted),
                  );
                }
                return Column(
                  children: [
                    for (final player in players)
                      ListTile(
                        onTap: () => context.push(AppRoutes.playerDetailsPath('${player.id}')),
                        leading: PlayerPhoto(name: player.name, url: player.photo, size: 40),
                        title: Text(player.name),
                        subtitle: Text(
                          [player.position, player.nationality]
                              .whereType<String>()
                              .where((part) => part.isNotEmpty)
                              .join(' · '),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(child: Text(value?.isNotEmpty == true ? value! : 'Unavailable')),
        ],
      ),
    );
  }
}
