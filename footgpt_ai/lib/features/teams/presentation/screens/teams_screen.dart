import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/football/featured_clubs.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/club_logo.dart';
import '../../../../core/widgets/data_notice.dart';
import '../../../../core/widgets/season_selector.dart';
import '../providers/teams_providers.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  String _query = '';
  String _country = 'All';

  static const _countries = [
    'All',
    'Spain',
    'England',
    'Germany',
    'France',
    'Italy',
    'Morocco',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(teamSearchProvider.notifier).loadCompetitions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamSearchProvider);
    final gutter = context.gutter();
    final featured = FeaturedClubs.clubs.where((club) {
      final q = _query.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          club.name.toLowerCase().contains(q) ||
          club.league.toLowerCase().contains(q);
      final matchesCountry = _country == 'All' || club.country == _country;
      return matchesQuery && matchesCountry;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
        children: [
          Text(
            'Crests are official API-Sports club logos. Season tables stay empty until Django syncs them.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          AppSearchField(
            hintText: 'Search Real Madrid, Wydad, Premier League…',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _countries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final country = _countries[index];
                final selected = country == _country;
                return ChoiceChip(
                  label: Text(country),
                  selected: selected,
                  selectedColor: AppColors.accentMuted,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.accent : AppColors.white,
                  ),
                  onSelected: (_) => setState(() => _country = country),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (featured.isEmpty)
            const DataNotice(message: 'No featured club matches that filter.')
          else
            for (final club in featured)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => context.push(
                    AppRoutes.teamDetailsPath(
                      '${club.id}',
                      league: '${club.leagueId}',
                    ),
                  ),
                  child: Row(
                    children: [
                      ClubLogo(name: club.name, url: club.logo, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.name,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${club.city} · ${club.country}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            Text(
                              club.league,
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 20),
          Text(
            'Competition catalog',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (state.competitions.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey(state.leagueId),
              initialValue: state.leagueId,
              dropdownColor: AppColors.surfaceElevated,
              decoration: const InputDecoration(labelText: 'Competition'),
              items: [
                for (final competition in state.competitions)
                  DropdownMenuItem(
                    value: competition.id,
                    child: Text('${competition.name} · ${competition.country ?? ''}'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(teamSearchProvider.notifier).setLeague(value);
                }
              },
            ),
          const SizedBox(height: 12),
          SeasonSelector(
            value: state.season,
            fullHistory: true,
            onChanged: ref.read(teamSearchProvider.notifier).setSeason,
          ),
          const SizedBox(height: 16),
          if (AppConstants.apiBaseUrl.isEmpty)
            const DataNotice(
              message:
                  'Sign in against Django to expand this list beyond the featured clubs.',
            )
          else if (state.loading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: AppLoader(message: 'Loading clubs from API-Football…'),
            )
          else if (state.error != null)
            AppErrorView(
              message: state.error!,
              onRetry: () => ref.read(teamSearchProvider.notifier).refreshClubs(),
            )
          else
            for (final club in state.clubs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => context.push(
                    AppRoutes.teamDetailsPath(
                      '${club.id}',
                      league: state.leagueId,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClubLogo(name: club.name, url: club.logo, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              [club.city, club.country]
                                  .where((part) => part != null && part.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
