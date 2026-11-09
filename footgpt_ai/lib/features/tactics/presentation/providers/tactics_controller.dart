import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/preview/preview_catalog.dart';
import '../../../../core/tactics/formation_templates.dart';
import '../../../../core/tactics/pitch_player.dart';
import '../../data/tactics_repository.dart';

class TacticsState {
  const TacticsState({
    this.formation = '4-3-3',
    this.players = const [],
    this.compareFormation = '4-4-2',
    this.comparePlayers = const [],
    this.saved = const [],
    this.selectedId,
    this.boardId,
    this.compareMode = false,
    this.loading = true,
    this.saving = false,
    this.suggesting = false,
    this.needsAuth = false,
    this.suggestion,
    this.error,
  });

  final String formation;
  final List<PitchPlayer> players;
  final String compareFormation;
  final List<PitchPlayer> comparePlayers;
  final List<TacticalBoardRecord> saved;
  final String? selectedId;
  final int? boardId;
  final bool compareMode;
  final bool loading;
  final bool saving;
  final bool suggesting;
  final bool needsAuth;
  final TacticsSuggestion? suggestion;
  final String? error;

  PitchPlayer? get selected {
    if (selectedId == null) return null;
    for (final player in players) {
      if (player.id == selectedId) return player;
    }
    return null;
  }

  TacticsState copyWith({
    String? formation,
    List<PitchPlayer>? players,
    String? compareFormation,
    List<PitchPlayer>? comparePlayers,
    List<TacticalBoardRecord>? saved,
    String? selectedId,
    int? boardId,
    bool? compareMode,
    bool? loading,
    bool? saving,
    bool? suggesting,
    bool? needsAuth,
    TacticsSuggestion? suggestion,
    String? error,
    bool clearSelected = false,
    bool clearBoardId = false,
    bool clearError = false,
    bool clearSuggestion = false,
  }) {
    return TacticsState(
      formation: formation ?? this.formation,
      players: players ?? this.players,
      compareFormation: compareFormation ?? this.compareFormation,
      comparePlayers: comparePlayers ?? this.comparePlayers,
      saved: saved ?? this.saved,
      selectedId: clearSelected ? null : selectedId ?? this.selectedId,
      boardId: clearBoardId ? null : boardId ?? this.boardId,
      compareMode: compareMode ?? this.compareMode,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      suggesting: suggesting ?? this.suggesting,
      needsAuth: needsAuth ?? this.needsAuth,
      suggestion: clearSuggestion ? null : suggestion ?? this.suggestion,
      error: clearError ? null : error ?? this.error,
    );
  }
}

List<PitchPlayer> _rosterFromPreview() {
  return PreviewCatalog.startingXi
      .map(
        (player) => PitchPlayer(
          id: player.id,
          name: player.name,
          position: player.position,
          x: 0.5,
          y: 0.5,
          number: player.number,
        ),
      )
      .toList();
}

class TacticsController extends Notifier<TacticsState> {
  @override
  TacticsState build() {
    final players = FormationTemplates.lineup(
      formation: '4-3-3',
      roster: _rosterFromPreview(),
    );
    final compare = FormationTemplates.lineup(
      formation: '4-4-2',
      roster: _rosterFromPreview(),
    );
    Future<void>.microtask(loadSaved);
    return TacticsState(
      players: players,
      comparePlayers: compare,
      loading: false,
    );
  }

  TacticsRepository get _repo => ref.read(tacticsRepositoryProvider);

  Future<void> loadSaved() async {
    try {
      final saved = await _repo.listBoards();
      state = state.copyWith(saved: saved, needsAuth: false, clearError: true);
    } on ApiException catch (error) {
      state = state.copyWith(
        needsAuth: error.isUnauthorized,
        error: error.isUnauthorized ? null : error.message,
      );
    }
  }

  void selectFormation(String formation) {
    state = state.copyWith(
      formation: formation,
      players: FormationTemplates.applyShape(
        formation: formation,
        players: state.players,
      ),
      clearBoardId: true,
    );
  }

  void selectCompareFormation(String formation) {
    state = state.copyWith(
      compareFormation: formation,
      comparePlayers: FormationTemplates.applyShape(
        formation: formation,
        players: state.comparePlayers,
      ),
    );
  }

  void selectPlayer(PitchPlayer player) {
    state = state.copyWith(selectedId: player.id);
  }

  void movePlayer(String id, double x, double y, {bool compare = false}) {
    if (compare) {
      state = state.copyWith(
        comparePlayers: [
          for (final player in state.comparePlayers)
            if (player.id == id) player.copyWith(x: x, y: y) else player,
        ],
      );
      return;
    }
    state = state.copyWith(
      selectedId: id,
      players: [
        for (final player in state.players)
          if (player.id == id) player.copyWith(x: x, y: y) else player,
      ],
    );
  }

  void removeSelected() {
    final id = state.selectedId;
    if (id == null) return;
    state = state.copyWith(
      players: state.players.where((player) => player.id != id).toList(),
      clearSelected: true,
      clearBoardId: true,
    );
  }

  void addPlayer(PitchPlayer player) {
    if (state.players.length >= 11) {
      state = state.copyWith(error: 'The pitch already has 11 players.');
      return;
    }
    if (state.players.any((item) => item.id == player.id)) return;
    final slots = FormationTemplates.slotsFor(state.formation);
    final index = state.players.length;
    final slot = index < slots.length ? slots[index] : slots.last;
    state = state.copyWith(
      players: [
        ...state.players,
        player.copyWith(position: slot.position, x: slot.x, y: slot.y),
      ],
      selectedId: player.id,
      clearError: true,
      clearBoardId: true,
    );
  }

  void toggleCompare(bool enabled) {
    state = state.copyWith(compareMode: enabled, clearSuggestion: true);
  }

  void loadBoard(TacticalBoardRecord board, {bool compare = false}) {
    if (compare) {
      state = state.copyWith(
        compareFormation: board.formation,
        comparePlayers: board.players,
        compareMode: true,
      );
      return;
    }
    state = state.copyWith(
      boardId: board.id,
      formation: board.formation,
      players: board.players,
      selectedId: board.players.isEmpty ? null : board.players.first.id,
      clearError: true,
    );
  }

  Future<void> save(String name) async {
    state = state.copyWith(saving: true, clearError: true);
    try {
      final saved = await _repo.saveBoard(
        id: state.boardId,
        name: name,
        formation: state.formation,
        players: state.players,
      );
      await loadSaved();
      state = state.copyWith(saving: false, boardId: saved.id);
    } on ApiException catch (error) {
      state = state.copyWith(
        saving: false,
        needsAuth: error.isUnauthorized,
        error: error.message,
      );
    }
  }

  Future<void> deleteSaved(int id) async {
    try {
      await _repo.deleteBoard(id);
      await loadSaved();
      if (state.boardId == id) {
        state = state.copyWith(clearBoardId: true);
      }
    } on ApiException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<void> requestSuggestion() async {
    state = state.copyWith(suggesting: true, clearError: true);
    try {
      final suggestion = await _repo.suggest(
        formation: state.formation,
        players: state.players,
        compareFormation: state.compareMode ? state.compareFormation : null,
        comparePlayers: state.compareMode ? state.comparePlayers : null,
      );
      state = state.copyWith(suggesting: false, suggestion: suggestion);
    } on ApiException catch (error) {
      state = state.copyWith(
        suggesting: false,
        needsAuth: error.isUnauthorized,
        error: error.message,
      );
    }
  }
}

final tacticsControllerProvider =
    NotifierProvider<TacticsController, TacticsState>(TacticsController.new);
