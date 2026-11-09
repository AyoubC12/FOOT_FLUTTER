import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/football/fixture_models.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_search_field.dart';
import '../../../../core/widgets/data_notice.dart';
import '../../../../core/widgets/fixture_card.dart';
import '../../data/matches_repository.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  List<FootballFixture> _filter(List<FootballFixture> rows) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return rows;
    return rows.where((fixture) {
      return (fixture.homeName ?? '').toLowerCase().contains(query) ||
          (fixture.awayName ?? '').toLowerCase().contains(query) ||
          (fixture.leagueName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gutter = context.gutter();
    final live = ref.watch(liveFixturesProvider);
    final upcoming = ref.watch(upcomingFixturesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.muted,
          tabs: const [
            Tab(text: 'Live'),
            Tab(text: 'Upcoming'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 8),
            child: AppSearchField(
              hintText: 'Filter by club or competition',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _FixturePane(
                  asyncRows: live,
                  filter: _filter,
                  empty:
                      'No live fixtures from API-Football. Scores are never invented.',
                ),
                _FixturePane(
                  asyncRows: upcoming,
                  filter: _filter,
                  empty: 'No upcoming fixtures were returned for this session.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixturePane extends StatelessWidget {
  const _FixturePane({
    required this.asyncRows,
    required this.filter,
    required this.empty,
  });

  final AsyncValue<List<FootballFixture>> asyncRows;
  final List<FootballFixture> Function(List<FootballFixture>) filter;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return asyncRows.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: DataNotice(message: '$error'),
      ),
      data: (rows) {
        final filtered = filter(rows);
        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: DataNotice(message: empty),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(context.gutter(), 8, context.gutter(), 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final fixture = filtered[index];
            return FixtureCard(
              fixture: fixture,
              onTap: () => context.push(AppRoutes.matchDetailsPath('${fixture.id}')),
            );
          },
        );
      },
    );
  }
}
