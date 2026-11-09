import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/football/featured_clubs.dart';
import '../../../../core/football/player_models.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/club_logo.dart';
import '../../../../core/widgets/data_notice.dart';
import '../../../../core/widgets/player_photo.dart';
import '../../../../core/widgets/season_selector.dart';
import '../providers/player_providers.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  String _position = 'All';

  static const _positions = ['All', 'Attacker', 'Midfielder', 'Defender', 'Goalkeeper'];

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(playerSearchProvider);
    final gutter = context.gutter();
    final results = search.results.where((player) {
      if (_position == 'All') return true;
      return (player.position ?? '').toLowerCase().contains(_position.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Players'),
        actions: [
          IconButton(
            tooltip: 'Compare',
            onPressed: () => context.push(AppRoutes.playerCompare),
            icon: const Icon(Icons.people_alt_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: [
          Text(
            'Photos come from API-Football player records. A missing photo stays blank — never swapped with another player.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          SeasonSelector(
            value: search.season,
            fullHistory: true,
            onChanged: ref.read(playerSearchProvider.notifier).setSeason,
          ),
          const SizedBox(height: 12),
          AppSearchField(
            hintText: 'Search by name (3+ letters)',
            onChanged: ref.read(playerSearchProvider.notifier).search,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _positions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final position = _positions[index];
                final selected = position == _position;
                return ChoiceChip(
                  label: Text(position),
                  selected: selected,
                  selectedColor: AppColors.accentMuted,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.accent : AppColors.white,
                  ),
                  onSelected: (_) => setState(() => _position = position),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Browse by club squad',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: FeaturedClubs.clubs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final club = FeaturedClubs.clubs[index];
                return AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onTap: () => context.push(
                    AppRoutes.teamDetailsPath(
                      '${club.id}',
                      league: '${club.leagueId}',
                    ),
                  ),
                  child: Row(
                    children: [
                      ClubLogo(name: club.name, url: club.logo, size: 36),
                      const SizedBox(width: 8),
                      Text(club.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (AppConstants.apiBaseUrl.isEmpty)
            const DataNotice(
              message:
                  'Connect Django with --dart-define=API_BASE_URL=... then search a verified player name.',
            )
          else if (search.loading)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: AppLoader(message: 'Searching players…'),
            )
          else if (search.error != null)
            AppErrorView(
              message: search.error!,
              onRetry: () =>
                  ref.read(playerSearchProvider.notifier).search(search.query),
            )
          else if (search.query.trim().length < 3 && search.teamId == null)
            const DataNotice(
              message:
                  'Type at least three letters to load verified player records and career statistics.',
            )
          else if (results.isEmpty)
            const DataNotice(message: 'No players were returned for that search.')
          else
            for (final player in results)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FootballPlayerTile(
                  player: player,
                  onTap: () => context.push(
                    AppRoutes.playerDetailsPath('${player.id}'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _FootballPlayerTile extends StatelessWidget {
  const _FootballPlayerTile({required this.player, required this.onTap});

  final FootballPlayer player;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    player.position,
                    player.teamName,
                    player.nationality,
                  ].whereType<String>().where((item) => item.isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _stat(player.goals, player.assists),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (player.age != null)
                Text(
                  '${player.age} yrs',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _stat(num? goals, num? assists) {
    final g = goals == null ? '—' : '$goals G';
    final a = assists == null ? '—' : '$assists A';
    return '$g · $a';
  }
}
