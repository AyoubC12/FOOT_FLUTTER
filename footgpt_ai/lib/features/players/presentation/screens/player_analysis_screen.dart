import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/football/player_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/history_chart.dart';
import '../../../../core/widgets/player_photo.dart';
import '../../../../core/widgets/season_selector.dart';
import '../../../../core/widgets/section_header.dart';
import '../providers/player_providers.dart';

class PlayerAnalysisScreen extends ConsumerStatefulWidget {
  const PlayerAnalysisScreen({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<PlayerAnalysisScreen> createState() =>
      _PlayerAnalysisScreenState();
}

class _PlayerAnalysisScreenState extends ConsumerState<PlayerAnalysisScreen> {
  late int _season = currentFootballSeason;

  @override
  Widget build(BuildContext context) {
    final id = int.tryParse(widget.playerId);
    final gutter = context.gutter();
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Player analysis')),
        body: const AppErrorView(
          message: 'This profile is not linked to an API-Football player id.',
        ),
      );
    }

    final async = ref.watch(
      playerDetailProvider(PlayerLookup(id: id, season: _season)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(async.asData?.value.player.name ?? 'Player analysis'),
      ),
      body: async.when(
        loading: () => const AppLoader(message: 'Loading verified statistics…'),
        error: (error, _) => AppErrorView(
          message: error is ApiException
              ? error.message
              : 'Could not load this player.',
          onRetry: () => ref.invalidate(
            playerDetailProvider(PlayerLookup(id: id, season: _season)),
          ),
        ),
        data: (detail) => ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
          children: [
            SeasonSelector(
            value: _season,
            fullHistory: true,
            onChanged: (season) => setState(() => _season = season),
          ),
            const SizedBox(height: 16),
            _PlayerHero(detail: detail),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      detail.player.position,
                      detail.player.teamName,
                    ].whereType<String>().where((item) => item.isNotEmpty).join(' · '),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _identityLine(detail.player),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  if (detail.player.leagueName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail.player.leagueName!,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Apps',
                    value: _fmt(detail.metrics['appearances']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    label: 'Goals',
                    value: _fmt(detail.metrics['goals']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatBox(
                    label: 'Assists',
                    value: _fmt(detail.metrics['assists']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Passing'),
            AppCard(
              child: Column(
                children: [
                  _kv('Passes', detail.metrics['passes']),
                  _kv('Key passes', detail.metrics['key_passes']),
                  _kv('Pass accuracy', detail.metrics['pass_accuracy']),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Defending'),
            AppCard(
              child: Column(
                children: [
                  _kv('Tackles', detail.metrics['tackles']),
                  _kv('Interceptions', detail.metrics['interceptions']),
                  _kv('Blocks', detail.metrics['blocks']),
                  _kv('Duels won', detail.metrics['duels_won']),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Available output'),
            AppCard(child: _MetricsChart(metrics: detail.metrics)),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Career seasons'),
            _CareerSeasons(playerId: id),
            const SizedBox(height: 20),
            AppButton(
              label: 'Compare player',
              icon: Icons.people_alt_rounded,
              onPressed: () => context.push(
                AppRoutes.comparePath(left: '${detail.player.id}'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Only API-Football values are shown. A dash means the provider did not return that statistic.',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  String _identityLine(FootballPlayer player) {
    final parts = <String>[
      if (player.age != null) 'Age ${player.age}',
      if (player.nationality != null && player.nationality!.isNotEmpty)
        player.nationality!,
    ];
    return parts.isEmpty ? 'Age and nationality unavailable' : parts.join(' · ');
  }
}

class _PlayerHero extends StatelessWidget {
  const _PlayerHero({required this.detail});

  final FootballPlayerDetail detail;

  @override
  Widget build(BuildContext context) {
    final player = detail.player;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.surfaceElevated),
            if (player.photo != null && player.photo!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: player.photo!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                memCacheWidth: 720,
                errorWidget: (_, _, _) => const SizedBox.shrink(),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Row(
                children: [
                  PlayerPhoto(name: player.name, url: player.photo, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          player.position ?? 'Position unavailable',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _fmt(player.rating),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsChart extends StatelessWidget {
  const _MetricsChart({required this.metrics});

  final Map<String, num?> metrics;

  @override
  Widget build(BuildContext context) {
    final bars = [
      for (final key in ['goals', 'assists', 'shots', 'key_passes', 'tackles', 'interceptions'])
        if (metrics[key] != null) (metricLabels[key] ?? key, metrics[key]!.toDouble()),
    ];
    if (bars.isEmpty) {
      return const Text(
        'No chartable statistics were returned for this season.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    final maxY = bars.map((item) => item.$2).reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 1 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    bars[index].$1.split(' ').first,
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < bars.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: bars[i].$2,
                    color: AppColors.accent,
                    width: 14,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CareerSeasons extends ConsumerWidget {
  const _CareerSeasons({required this.playerId});

  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playerCareerProvider(playerId));
    return async.when(
      loading: () => const Text(
        'Loading stored career seasons…',
        style: TextStyle(color: AppColors.muted),
      ),
      error: (_, _) => const Text(
        'Career seasons are unavailable until statistics have been stored.',
        style: TextStyle(color: AppColors.muted),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Text(
            'No stored career rows yet. Open a season above to persist verified stats.',
            style: TextStyle(color: AppColors.muted),
          );
        }
        final goals = [
          for (final row in rows.reversed)
            if (row.goals != null) SeasonPoint(year: row.year, value: row.goals!),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HistoryChart(points: goals),
            for (final row in rows)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${row.label} · ${row.teamName ?? 'Club unavailable'}'),
                subtitle: Text(
                  [
                    if (row.appearances != null) '${row.appearances} apps',
                    if (row.goals != null) '${row.goals} goals',
                    if (row.assists != null) '${row.assists} assists',
                    if (row.missingFields.isNotEmpty)
                      'missing ${row.missingFields.join(', ')}',
                  ].join(' · '),
                ),
              ),
          ],
        );
      },
    );
  }
}

Widget _kv(String label, num? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
        Text(
          _fmt(value),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

String _fmt(num? value) {
  if (value == null) return '—';
  if (value is int || value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}
