import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/preview/preview_catalog.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/match_card.dart';
import '../../../../core/widgets/player_tile.dart';
import '../../../../core/widgets/preview_banner.dart';
import '../../../../core/widgets/team_crest.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.watch(favoritesProvider);
    final gutter = context.gutter();
    final matches = PreviewCatalog.matches
        .where((match) => fav.matchIds.contains(match.id))
        .toList();
    final players = PreviewCatalog.players
        .where((player) => fav.playerIds.contains(player.id))
        .toList();
    final teams = PreviewCatalog.teams
        .where((team) => fav.teamIds.contains(team.id))
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favorites'),
          bottom: const TabBar(
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.muted,
            tabs: [
              Tab(text: 'Matches'),
              Tab(text: 'Players'),
              Tab(text: 'Clubs'),
            ],
          ),
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PreviewBanner(label: 'Local preview watchlist'),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _EmptyOr(
                    isEmpty: matches.isEmpty,
                    child: ListView.separated(
                      padding: EdgeInsets.all(gutter),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return MatchCard(
                          match: match,
                          onTap: () => context.push(
                            AppRoutes.matchDetailsPath(match.id),
                          ),
                        );
                      },
                    ),
                  ),
                  _EmptyOr(
                    isEmpty: players.isEmpty,
                    child: ListView.separated(
                      padding: EdgeInsets.all(gutter),
                      itemCount: players.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return PlayerTile(
                          player: player,
                          onTap: () => context.push(
                            AppRoutes.playerDetailsPath(player.id),
                          ),
                        );
                      },
                    ),
                  ),
                  _EmptyOr(
                    isEmpty: teams.isEmpty,
                    child: ListView(
                      padding: EdgeInsets.all(gutter),
                      children: [
                        for (final team in teams)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () => context.go(AppRoutes.matches),
                              child: Row(
                                children: [
                                  TeamCrest(team: team),
                                  const SizedBox(width: 12),
                                  Text(
                                    team.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => ref
                                        .read(favoritesProvider.notifier)
                                        .toggleTeam(team.id),
                                    icon: const Icon(
                                      Icons.bookmark_rounded,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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

class _EmptyOr extends StatelessWidget {
  const _EmptyOr({required this.isEmpty, required this.child});

  final bool isEmpty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!isEmpty) return child;
    return const Center(
      child: Text(
        'Nothing pinned yet. Save from a match or player card.',
        style: TextStyle(color: AppColors.muted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
