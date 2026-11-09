import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/tactics/pitch_player.dart';

class TacticsSuggestion {
  const TacticsSuggestion({
    required this.text,
    required this.tips,
    required this.source,
    required this.disclaimer,
  });

  final String text;
  final List<String> tips;
  final String source;
  final String disclaimer;
}

class TacticsRepository {
  TacticsRepository(this._client);

  final ApiClient _client;

  Future<List<TacticalBoardRecord>> listBoards() async {
    if (!_client.hasBaseUrl) return [];
    final token = await _client.tokens.readAccess();
    if (token == null || token.isEmpty) {
      throw const ApiException('Sign in to save tactical boards.', statusCode: 401);
    }
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.tacticBoards,
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => TacticalBoardRecord.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TacticalBoardRecord> saveBoard({
    int? id,
    required String name,
    required String formation,
    required List<PitchPlayer> players,
  }) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
    final body = {
      'name': name,
      'formation': formation,
      'players': players.map((player) => player.toJson()).toList(),
    };
    final response = id == null
        ? await _client.post<Map<String, dynamic>>(ApiPaths.tacticBoards, data: body)
        : await _client.patch<Map<String, dynamic>>(
            ApiPaths.tacticBoard(id),
            data: body,
          );
    return TacticalBoardRecord.fromJson(response.data ?? {});
  }

  Future<void> deleteBoard(int id) async {
    await _client.delete(ApiPaths.tacticBoard(id));
  }

  Future<TacticsSuggestion> suggest({
    required String formation,
    required List<PitchPlayer> players,
    String? compareFormation,
    List<PitchPlayer>? comparePlayers,
  }) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.tacticSuggest,
      data: {
        'formation': formation,
        'players': players.map((player) => player.toJson()).toList(),
        if (compareFormation != null && comparePlayers != null)
          'compare': {
            'formation': compareFormation,
            'players': comparePlayers.map((player) => player.toJson()).toList(),
          },
      },
      receiveTimeout: const Duration(seconds: 45),
    );
    final data = response.data ?? {};
    final tips = (data['structural_tips'] as List?)?.map((item) => '$item').toList() ??
        const <String>[];
    return TacticsSuggestion(
      text: '${data['suggestion'] ?? ''}',
      tips: tips,
      source: '${data['source'] ?? 'verified_notes'}',
      disclaimer: '${data['disclaimer'] ?? ''}',
    );
  }
}

final tacticsRepositoryProvider = Provider<TacticsRepository>((ref) {
  return TacticsRepository(ref.watch(apiClientProvider));
});
