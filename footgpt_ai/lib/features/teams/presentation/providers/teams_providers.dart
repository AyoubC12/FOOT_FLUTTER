import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/football/featured_clubs.dart';
import '../../../../core/football/football_seasons.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/teams_repository.dart';
import '../../domain/team_models.dart';

class TeamSearchState {
  const TeamSearchState({
    this.competitions = const [],
    this.clubs = const [],
    this.leagueId,
    this.season = 0,
    this.query = '',
    this.country = '',
    this.loading = false,
    this.error,
  });

  final List<FootballCompetition> competitions;
  final List<FootballClub> clubs;
  final String? leagueId;
  final int season;
  final String query;
  final String country;
  final bool loading;
  final String? error;

  TeamSearchState copyWith({
    List<FootballCompetition>? competitions,
    List<FootballClub>? clubs,
    String? leagueId,
    int? season,
    String? query,
    String? country,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return TeamSearchState(
      competitions: competitions ?? this.competitions,
      clubs: clubs ?? this.clubs,
      leagueId: leagueId ?? this.leagueId,
      season: season ?? this.season,
      query: query ?? this.query,
      country: country ?? this.country,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class TeamSearchController extends Notifier<TeamSearchState> {
  @override
  TeamSearchState build() {
    return TeamSearchState(season: FootballSeasons.currentStartYear);
  }

  Future<void> loadCompetitions() async {
    if (AppConstants.apiBaseUrl.isEmpty) return;
    try {
      final rows = await ref.read(teamsRepositoryProvider).competitions();
      state = state.copyWith(
        competitions: rows,
        leagueId: state.leagueId ?? (rows.isNotEmpty ? rows.first.id : null),
        clearError: true,
      );
      if (state.leagueId != null) {
        await refreshClubs();
      }
    } on ApiException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<void> setLeague(String id) async {
    state = state.copyWith(leagueId: id);
    await refreshClubs();
  }

  Future<void> setSeason(int season) async {
    state = state.copyWith(season: season);
    await refreshClubs();
  }

  Future<void> search(String query) async {
    state = state.copyWith(query: query);
    await refreshClubs();
  }

  Future<void> setCountry(String country) async {
    state = state.copyWith(country: country);
    await refreshClubs();
  }

  Future<void> refreshClubs() async {
    final league = int.tryParse(state.leagueId ?? '');
    if (league == null || AppConstants.apiBaseUrl.isEmpty) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final clubs = await ref.read(teamsRepositoryProvider).list(
            leagueId: league,
            season: state.season,
            search: state.query.trim().isEmpty ? null : state.query,
            country: state.country.isEmpty ? null : state.country,
          );
      state = state.copyWith(clubs: clubs, loading: false);
    } on ApiException catch (error) {
      state = state.copyWith(loading: false, error: error.message, clubs: const []);
    }
  }
}

final teamSearchProvider =
    NotifierProvider<TeamSearchController, TeamSearchState>(TeamSearchController.new);

final teamDetailProvider = FutureProvider.family<FootballClub, int>((ref, id) async {
    try {
      return await ref.read(teamsRepositoryProvider).detail(id);
    } on ApiException {
    final featured = FeaturedClubs.byId(id);
    if (featured != null) return featured.toClub();
    rethrow;
  }
});

class TeamHistoryLookup {
  const TeamHistoryLookup({required this.teamId, this.leagueId});

  final int teamId;
  final int? leagueId;

  @override
  bool operator ==(Object other) =>
      other is TeamHistoryLookup &&
      other.teamId == teamId &&
      other.leagueId == leagueId;

  @override
  int get hashCode => Object.hash(teamId, leagueId);
}

final teamSeasonsProvider =
    FutureProvider.family<List<TeamSeasonRow>, TeamHistoryLookup>((ref, lookup) async {
  return ref.read(teamsRepositoryProvider).seasons(
        lookup.teamId,
        leagueId: lookup.leagueId,
      );
});

final teamSquadProvider = FutureProvider.family((ref, int id) async {
  return ref.read(teamsRepositoryProvider).squad(id);
});
