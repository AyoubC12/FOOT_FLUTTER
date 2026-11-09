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
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/player_photo.dart';
import '../../../../core/widgets/player_radar_chart.dart';
import '../../../../core/widgets/season_selector.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_bar.dart';
import '../../data/players_repository.dart';
import '../providers/player_providers.dart';

class PlayerComparisonScreen extends ConsumerStatefulWidget {
  const PlayerComparisonScreen({super.key, this.leftId, this.rightId});

  final String? leftId;
  final String? rightId;

  @override
  ConsumerState<PlayerComparisonScreen> createState() =>
      _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState
    extends ConsumerState<PlayerComparisonScreen> {
  late int _season = currentFootballSeason;
  int? _leftId;
  int? _rightId;
  bool _saving = false;
  String? _saveMessage;

  @override
  void initState() {
    super.initState();
    _leftId = int.tryParse(widget.leftId ?? '');
    _rightId = int.tryParse(widget.rightId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    final canCompare =
        _leftId != null && _rightId != null && _leftId != _rightId;
    final async = canCompare
        ? ref.watch(
            playerCompareProvider(
              CompareLookup(
                leftId: _leftId!,
                rightId: _rightId!,
                season: _season,
              ),
            ),
          )
        : null;
    final saved = ref.watch(savedComparisonsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Player comparison')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 28),
        children: [
          SeasonSelector(
            value: _season,
            onChanged: (season) => setState(() => _season = season),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SelectCard(
                  label: 'Player A',
                  player: async?.asData?.value.left.player,
                  onPick: () => _pick(isLeft: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectCard(
                  label: 'Player B',
                  player: async?.asData?.value.right.player,
                  onPick: () => _pick(isLeft: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!canCompare)
            const Text(
              'Select two different API-Football players to compare verified statistics.',
              style: TextStyle(color: AppColors.muted),
            )
          else
            async!.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: AppLoader(message: 'Comparing verified statistics…'),
              ),
              error: (error, _) => AppErrorView(
                message: error is ApiException
                    ? error.message
                    : 'Comparison failed.',
                onRetry: () => ref.invalidate(
                  playerCompareProvider(
                    CompareLookup(
                      leftId: _leftId!,
                      rightId: _rightId!,
                      season: _season,
                    ),
                  ),
                ),
              ),
              data: (result) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Side by side'),
                  Row(
                    children: [
                      Expanded(child: _MiniCard(player: result.left.player)),
                      const SizedBox(width: 12),
                      Expanded(child: _MiniCard(player: result.right.player)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Radar (shared stats only)'),
                  AppCard(child: PlayerRadarChart(rows: result.rows)),
                  const SizedBox(height: 16),
                  const SectionHeader(title: 'Statistical differences'),
                  AppCard(
                    child: Column(
                      children: [
                        for (final row in result.rows)
                          StatBar.nullable(
                            label: row.label,
                            leftValue: row.left,
                            rightValue: row.right,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.disclaimer,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Save comparison',
                    icon: Icons.bookmark_add_outlined,
                    isLoading: _saving,
                    onPressed: _save,
                  ),
                  if (_saveMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_saveMessage!, style: const TextStyle(color: AppColors.accent)),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Saved comparisons'),
          saved.when(
            loading: () => const AppLoader(),
            error: (error, _) => Text(
              error is ApiException ? error.message : 'Could not load saved comparisons.',
              style: const TextStyle(color: AppColors.muted),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const Text(
                  'Saved comparisons appear here after you persist a pair.',
                  style: TextStyle(color: AppColors.muted),
                );
              }
              return Column(
                children: [
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        onTap: () {
                          setState(() {
                            _leftId = item.leftPlayerId;
                            _rightId = item.rightPlayerId;
                            _season = item.season;
                          });
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.leftName} vs ${item.rightName}\nSeason ${item.season}',
                              ),
                            ),
                            IconButton(
                              onPressed: () async {
                                await ref
                                    .read(playersRepositoryProvider)
                                    .deleteSaved(item.id);
                                ref.invalidate(savedComparisonsProvider);
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pick({required bool isLeft}) async {
    final selected = await showModalBottomSheet<FootballPlayer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (context) => _PlayerSearchSheet(season: _season),
    );
    if (selected == null) return;
    setState(() {
      if (isLeft) {
        _leftId = selected.id;
      } else {
        _rightId = selected.id;
      }
    });
  }

  Future<void> _save() async {
    if (_leftId == null || _rightId == null) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    try {
      await ref.read(playersRepositoryProvider).saveComparison(
            leftId: _leftId!,
            rightId: _rightId!,
            season: _season,
          );
      ref.invalidate(savedComparisonsProvider);
      if (mounted) {
        setState(() {
          _saving = false;
          _saveMessage = 'Comparison saved.';
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveMessage = error.message;
        });
      }
    }
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.label,
    required this.onPick,
    this.player,
  });

  final String label;
  final FootballPlayer? player;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onPick,
      child: Column(
        children: [
          if (player == null)
            const Icon(Icons.person_search_rounded, color: AppColors.muted)
          else
            PlayerPhoto(name: player!.name, url: player!.photo, size: 64),
          const SizedBox(height: 8),
          Text(
            player?.name ?? label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            player?.position ?? 'Tap to search',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.player});

  final FootballPlayer player;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(AppRoutes.playerDetailsPath('${player.id}')),
      child: Column(
        children: [
          PlayerPhoto(name: player.name, url: player.photo, size: 56),
          const SizedBox(height: 8),
          Text(player.name, textAlign: TextAlign.center),
          Text(
            [player.teamName, player.nationality]
                .whereType<String>()
                .where((item) => item.isNotEmpty)
                .join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlayerSearchSheet extends ConsumerStatefulWidget {
  const _PlayerSearchSheet({required this.season});

  final int season;

  @override
  ConsumerState<_PlayerSearchSheet> createState() => _PlayerSearchSheetState();
}

class _PlayerSearchSheetState extends ConsumerState<_PlayerSearchSheet> {
  List<FootballPlayer> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(playersRepositoryProvider).search(
            query: query.trim(),
            season: widget.season,
          );
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppSearchField(
              hintText: 'Search player',
              onChanged: _search,
            ),
            const SizedBox(height: 12),
            if (_loading) const AppLoader(),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
            Expanded(
              child: ListView(
                children: [
                  for (final player in _results)
                    ListTile(
                      leading: PlayerPhoto(
                        name: player.name,
                        url: player.photo,
                        size: 40,
                      ),
                      title: Text(player.name),
                      subtitle: Text(
                        [player.position, player.teamName]
                            .whereType<String>()
                            .join(' · '),
                      ),
                      onTap: () => Navigator.pop(context, player),
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
