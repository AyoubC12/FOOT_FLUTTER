import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/football/football_seasons.dart';
import '../../../../core/football/player_models.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/players_repository.dart';

int get currentFootballSeason => FootballSeasons.currentStartYear;

class PlayerLookup {
  const PlayerLookup({required this.id, required this.season});

  final int id;
  final int season;

  @override
  bool operator ==(Object other) =>
      other is PlayerLookup && other.id == id && other.season == season;

  @override
  int get hashCode => Object.hash(id, season);
}

class CompareLookup {
  const CompareLookup({
    required this.leftId,
    required this.rightId,
    required this.season,
  });

  final int leftId;
  final int rightId;
  final int season;

  @override
  bool operator ==(Object other) =>
      other is CompareLookup &&
      other.leftId == leftId &&
      other.rightId == rightId &&
      other.season == season;

  @override
  int get hashCode => Object.hash(leftId, rightId, season);
}

class PlayerSearchState {
  const PlayerSearchState({
    this.query = '',
    this.season = 0,
    this.teamId,
    this.results = const [],
    this.loading = false,
    this.error,
  });

  final String query;
  final int season;
  final int? teamId;
  final List<FootballPlayer> results;
  final bool loading;
  final String? error;

  PlayerSearchState copyWith({
    String? query,
    int? season,
    int? teamId,
    bool clearTeam = false,
    List<FootballPlayer>? results,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PlayerSearchState(
      query: query ?? this.query,
      season: season ?? this.season,
      teamId: clearTeam ? null : teamId ?? this.teamId,
      results: results ?? this.results,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class PlayerSearchController extends Notifier<PlayerSearchState> {
  Timer? _debounce;

  @override
  PlayerSearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return PlayerSearchState(season: currentFootballSeason);
  }

  void setSeason(int season) {
    state = state.copyWith(season: season);
    _schedule();
  }

  void setTeamId(String raw) {
    final id = int.tryParse(raw.trim());
    state = state.copyWith(teamId: id, clearTeam: id == null, clearError: true);
    _schedule();
  }

  void search(String raw) {
    state = state.copyWith(query: raw.trim(), clearError: true);
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    if (state.query.length < 3 && state.teamId == null) {
      state = state.copyWith(results: const [], loading: false);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _run);
  }

  Future<void> _run() async {
    final query = state.query;
    final teamId = state.teamId;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final results = await ref.read(playersRepositoryProvider).search(
            query: query,
            season: state.season,
            teamId: teamId,
          );
      if (state.query.trim() != query) return;
      state = state.copyWith(results: results, loading: false);
    } on ApiException catch (error) {
      state = state.copyWith(loading: false, error: error.message);
    } catch (error) {
      state = state.copyWith(loading: false, error: '$error');
    }
  }
}

final playerSearchProvider =
    NotifierProvider<PlayerSearchController, PlayerSearchState>(
      PlayerSearchController.new,
    );

final playerDetailProvider =
    FutureProvider.family<FootballPlayerDetail, PlayerLookup>((ref, lookup) {
      return ref.read(playersRepositoryProvider).statistics(
            playerId: lookup.id,
            season: lookup.season,
          );
    });

final playerCompareProvider =
    FutureProvider.family<PlayerComparisonResult, CompareLookup>((ref, lookup) {
      return ref.read(playersRepositoryProvider).compare(
            leftId: lookup.leftId,
            rightId: lookup.rightId,
            season: lookup.season,
          );
    });

final savedComparisonsProvider = FutureProvider<List<SavedComparison>>((ref) {
  return ref.read(playersRepositoryProvider).saved();
});

final playerCareerProvider =
    FutureProvider.family<List<PlayerSeasonRow>, int>((ref, playerId) {
  return ref.read(playersRepositoryProvider).seasons(playerId);
});
