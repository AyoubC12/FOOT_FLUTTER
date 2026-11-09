import 'package:flutter_riverpod/flutter_riverpod.dart';

class FavoritesState {
  const FavoritesState({
    required this.matchIds,
    required this.playerIds,
    required this.teamIds,
  });

  final Set<String> matchIds;
  final Set<String> playerIds;
  final Set<String> teamIds;

  FavoritesState copyWith({
    Set<String>? matchIds,
    Set<String>? playerIds,
    Set<String>? teamIds,
  }) {
    return FavoritesState(
      matchIds: matchIds ?? this.matchIds,
      playerIds: playerIds ?? this.playerIds,
      teamIds: teamIds ?? this.teamIds,
    );
  }
}

class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() {
    return const FavoritesState(
      matchIds: {'m-up-1'},
      playerIds: {'saka', 'yamal'},
      teamIds: {'ars', 'rma'},
    );
  }

  void toggleMatch(String id) {
    final next = {...state.matchIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(matchIds: next);
  }

  void togglePlayer(String id) {
    final next = {...state.playerIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(playerIds: next);
  }

  void toggleTeam(String id) {
    final next = {...state.teamIds};
    next.contains(id) ? next.remove(id) : next.add(id);
    state = state.copyWith(teamIds: next);
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, FavoritesState>(FavoritesNotifier.new);
