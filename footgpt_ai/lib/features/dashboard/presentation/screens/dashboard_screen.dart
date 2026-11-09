import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/football/featured_clubs.dart';
import '../../../../core/preview/preview_catalog.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/club_logo.dart';
import '../../../../core/widgets/data_notice.dart';
import '../../../../core/widgets/fixture_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../matches/data/matches_repository.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gutter = context.gutter();
    final live = ref.watch(liveFixturesProvider);
    final upcoming = ref.watch(upcomingFixturesProvider);
    final hour = DateTime.now().hour;
    final hello = hour < 12
        ? 'Good morning'
        : hour < 18
        ? 'Good afternoon'
        : 'Good evening';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background.withValues(alpha: 0.92),
              title: const BrandMark(showWordmark: true),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => context.push(AppRoutes.notifications),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.profile),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accentMuted,
                      child: Text(
                        PreviewCatalog.userName[0],
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
              sliver: SliverList.list(
                children: [
                  Text(
                    '$hello, ${PreviewCatalog.userName}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Live scores, clubs and history load from Django + API-Football. Missing values stay blank.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Live matches',
                    actionLabel: 'All matches',
                    onAction: () => context.go(AppRoutes.matches),
                  ),
                  live.when(
                    loading: () => const _LoadingStrip(label: 'Checking live fixtures…'),
                    error: (error, _) => DataNotice(message: '$error'),
                    data: (rows) {
                      if (rows.isEmpty) {
                        return const DataNotice(
                          icon: Icons.sensors_rounded,
                          message:
                              'No live fixtures were returned. Start Django and set FOOTBALL_API_KEY to stream real scores.',
                        );
                      }
                      return Column(
                        children: [
                          for (final fixture in rows.take(4))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: FixtureCard(
                                fixture: fixture,
                                onTap: () => context.push(
                                  AppRoutes.matchDetailsPath('${fixture.id}'),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  SectionHeader(
                    title: 'Upcoming matches',
                    actionLabel: 'See all',
                    onAction: () => context.go(AppRoutes.matches),
                  ),
                  upcoming.when(
                    loading: () => const _LoadingStrip(label: 'Loading upcoming slate…'),
                    error: (error, _) => DataNotice(message: '$error'),
                    data: (rows) {
                      if (rows.isEmpty) {
                        return const DataNotice(
                          message:
                              'Upcoming kick-offs appear here once fixtures are synced from API-Football.',
                        );
                      }
                      return SizedBox(
                        height: 188,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: rows.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final fixture = rows[index];
                            return SizedBox(
                              width: 280,
                              child: FixtureCard(
                                fixture: fixture,
                                compact: true,
                                onTap: () => context.push(
                                  AppRoutes.matchDetailsPath('${fixture.id}'),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Football news'),
                  _NewsDesk(onOpenTeams: () => context.push(AppRoutes.teams)),
                  const SizedBox(height: 24),
                  const SectionHeader(title: 'Quick access'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _QuickTile(
                        label: 'AI Assistant',
                        icon: Icons.auto_awesome,
                        onTap: () => context.go(AppRoutes.chatbot),
                      ),
                      _QuickTile(
                        label: 'Predictions',
                        icon: Icons.insights_rounded,
                        onTap: () => context.push(AppRoutes.predictions),
                      ),
                      _QuickTile(
                        label: 'Teams',
                        icon: Icons.shield_rounded,
                        onTap: () => context.push(AppRoutes.teams),
                      ),
                      _QuickTile(
                        label: 'Players',
                        icon: Icons.person_search_rounded,
                        onTap: () => context.push(AppRoutes.players),
                      ),
                      _QuickTile(
                        label: 'Statistics',
                        icon: Icons.bar_chart_rounded,
                        onTap: () => context.go(AppRoutes.stats),
                      ),
                      _QuickTile(
                        label: 'Tactical Analysis',
                        icon: Icons.schema_rounded,
                        onTap: () => context.push(AppRoutes.tactics),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'Featured clubs',
                    actionLabel: 'All teams',
                    onAction: () => context.push(AppRoutes.teams),
                  ),
                  SizedBox(
                    height: 108,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: FeaturedClubs.clubs.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final club = FeaturedClubs.clubs[index];
                        return AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onTap: () => context.push(
                            AppRoutes.teamDetailsPath(
                              '${club.id}',
                              league: '${club.leagueId}',
                            ),
                          ),
                          child: SizedBox(
                            width: 92,
                            child: Column(
                              children: [
                                ClubLogo(name: club.name, url: club.logo, size: 42),
                                const SizedBox(height: 8),
                                Text(
                                  club.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (AppConstants.apiBaseUrl.isEmpty) ...[
                    const SizedBox(height: 16),
                    const DataNotice(
                      message:
                          'API_BASE_URL is empty. Run Flutter with --dart-define=API_BASE_URL=http://127.0.0.1:8000 after starting Django.',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsDesk extends StatelessWidget {
  const _NewsDesk({required this.onOpenTeams});

  final VoidCallback onOpenTeams;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DataNotice(
          icon: Icons.newspaper_rounded,
          message:
              'Match headlines and dated articles are not invented in the app. Wire a news source on Django to populate this desk.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: FeaturedClubs.competitions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final league = FeaturedClubs.competitions[index];
              return AppCard(
                onTap: onOpenTeams,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: SizedBox(
                  width: 168,
                  child: Row(
                    children: [
                      ClubLogo(name: league.name, url: league.logo, size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              league.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              league.country,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 52) / 2,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: AppColors.accentMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingStrip extends StatelessWidget {
  const _LoadingStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}
