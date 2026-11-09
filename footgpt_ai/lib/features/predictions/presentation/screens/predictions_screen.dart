import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/football/featured_clubs.dart';
import '../../../../core/football/football_seasons.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/club_logo.dart';
import '../../../../core/widgets/data_notice.dart';
import '../../../../core/widgets/probability_chart.dart';
import '../../../teams/domain/team_models.dart';
import '../../../teams/presentation/providers/teams_providers.dart';
import '../../data/predictions_repository.dart';

class PredictionsScreen extends ConsumerStatefulWidget {
  const PredictionsScreen({super.key});

  @override
  ConsumerState<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends ConsumerState<PredictionsScreen> {
  FeaturedClub _home = FeaturedClubs.clubs[5];
  FeaturedClub _away = FeaturedClubs.clubs[4];
  bool _loading = false;
  String? _error;
  MatchEstimate? _estimate;

  Future<void> _run() async {
    if (_home.id == _away.id) {
      setState(() => _error = 'Pick two different clubs.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final estimate = await ref.read(predictionsRepositoryProvider).estimate(
            homeId: _home.id,
            awayId: _away.id,
            homeName: _home.name,
            awayName: _away.name,
            leagueId: _home.leagueId,
            season: FootballSeasons.currentStartYear,
          );
      if (mounted) {
        setState(() {
          _estimate = estimate;
          _loading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    final homeHistory = ref.watch(
      teamSeasonsProvider(
        TeamHistoryLookup(teamId: _home.id, leagueId: _home.leagueId),
      ),
    );
    final awayHistory = ref.watch(
      teamSeasonsProvider(
        TeamHistoryLookup(teamId: _away.id, leagueId: _away.leagueId),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match predictions'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.dashboard);
            }
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
        children: [
          const DataNotice(
            icon: Icons.gavel_rounded,
            message:
                'Probabilities are model estimates routed through Django. They are never a guaranteed result.',
          ),
          const SizedBox(height: 16),
          _TeamPicker(
            label: 'Home team',
            value: _home,
            onChanged: (club) => setState(() => _home = club),
          ),
          const SizedBox(height: 12),
          _TeamPicker(
            label: 'Away team',
            value: _away,
            onChanged: (club) => setState(() => _away = club),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: _loading ? 'Estimating…' : 'Compute probabilities',
            icon: Icons.insights_rounded,
            isLoading: _loading,
            onPressed: _run,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            DataNotice(message: _error!, icon: Icons.error_outline_rounded),
          ],
          if (_estimate != null) ...[
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                children: [
                  ProbabilityChart(
                    home: _estimate!.homePct,
                    draw: _estimate!.drawPct,
                    away: _estimate!.awayPct,
                  ),
                  const SizedBox(height: 8),
                  _ProbRow(label: 'Home win', value: _estimate!.homePct, color: AppColors.accent),
                  _ProbRow(label: 'Draw', value: _estimate!.drawPct, color: AppColors.muted),
                  _ProbRow(label: 'Away win', value: _estimate!.awayPct, color: AppColors.info),
                  const SizedBox(height: 8),
                  Text(
                    _estimate!.disclaimer ??
                        'This is a probabilistic estimate, not a guaranteed outcome.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  if (_estimate!.explanation != null) ...[
                    const SizedBox(height: 8),
                    Text(_estimate!.explanation!),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Stored season comparison',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: [
                _CompareLine(
                  label: 'Club',
                  left: _home.name,
                  right: _away.name,
                ),
                homeHistory.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Comparison stats appear after a catalog sync.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  data: (homeRows) {
                    final awayRows = awayHistory.asData?.value ?? const [];
                    final year = FootballSeasons.currentStartYear;
                    TeamSeasonRow? home;
                    TeamSeasonRow? away;
                    for (final row in homeRows) {
                      if (row.year == year) home = row;
                    }
                    for (final row in awayRows) {
                      if (row.year == year) away = row;
                    }
                    if (home == null && away == null) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'No stored current-season rows for this pairing yet.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        _CompareLine(label: 'Points', left: '${home?.points ?? '—'}', right: '${away?.points ?? '—'}'),
                        _CompareLine(label: 'Played', left: '${home?.played ?? '—'}', right: '${away?.played ?? '—'}'),
                        _CompareLine(label: 'Goals', left: '${home?.goalsFor ?? '—'}', right: '${away?.goalsFor ?? '—'}'),
                        _CompareLine(label: 'Position', left: '${home?.rank ?? '—'}', right: '${away?.rank ?? '—'}'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamPicker extends StatelessWidget {
  const _TeamPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final FeaturedClub value;
  final ValueChanged<FeaturedClub> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: value.id,
            dropdownColor: AppColors.surfaceElevated,
            items: [
              for (final club in FeaturedClubs.clubs)
                DropdownMenuItem(
                  value: club.id,
                  child: Row(
                    children: [
                      ClubLogo(name: club.name, url: club.logo, size: 24),
                      const SizedBox(width: 8),
                      Text(club.name),
                    ],
                  ),
                ),
            ],
            onChanged: (id) {
              final club = FeaturedClubs.byId(id ?? 0);
              if (club != null) onChanged(club);
            },
          ),
        ],
      ),
    );
  }
}

class _ProbRow extends StatelessWidget {
  const _ProbRow({required this.label, required this.value, required this.color});

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CompareLine extends StatelessWidget {
  const _CompareLine({required this.label, required this.left, required this.right});

  final String label;
  final String left;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(left, textAlign: TextAlign.left)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Expanded(child: Text(right, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}
