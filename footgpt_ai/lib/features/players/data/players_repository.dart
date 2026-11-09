import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/football/player_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';
import '../domain/players_gateway.dart';

class PlayersRepository implements PlayersGateway {
  PlayersRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<FootballPlayer>> search({
    required String query,
    required int season,
    int? teamId,
  }) async {
    _requireApi();
    await _requireAuth();
    if (query.trim().length < 3 && teamId == null) {
      return const [];
    }
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.footballPlayers,
      queryParameters: {
        'season': season,
        'search': ?(query.trim().length >= 3 ? query.trim() : null),
        'team': ?teamId,
      },
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => FootballPlayer.fromJson(item as Map<String, dynamic>))
        .where((player) => player.id > 0)
        .toList();
  }

  @override
  Future<FootballPlayerDetail> statistics({
    required int playerId,
    required int season,
  }) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.playerStatistics(playerId),
      queryParameters: {'season': season},
    );
    final results = response.data?['results'];
    if (results is! Map<String, dynamic> || results['id'] == null) {
      throw const ApiException('No verified statistics were returned for that player.');
    }
    return FootballPlayerDetail.fromJson(results);
  }

  @override
  Future<PlayerComparisonResult> compare({
    required int leftId,
    required int rightId,
    required int season,
  }) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.playerCompare,
      queryParameters: {
        'left': leftId,
        'right': rightId,
        'season': season,
      },
    );
    return PlayerComparisonResult.fromJson(response.data ?? {});
  }

  Future<List<SavedComparison>> saved() async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.playerComparisons,
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => SavedComparison.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SavedComparison> saveComparison({
    required int leftId,
    required int rightId,
    required int season,
  }) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.playerComparisons,
      data: {
        'left_player_id': leftId,
        'right_player_id': rightId,
        'season': season,
      },
    );
    return SavedComparison.fromJson(response.data ?? {});
  }

  Future<List<PlayerSeasonRow>> seasons(int playerId) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.playerSeasons(playerId),
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => PlayerSeasonRow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteSaved(int id) async {
    await _client.delete(ApiPaths.playerComparison(id));
  }

  void _requireApi() {
    if (!_client.hasBaseUrl) {
      throw const ApiException('API is not configured.');
    }
  }

  Future<void> _requireAuth() async {
    final token = await _client.tokens.readAccess();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sign in to load API-Football player statistics.',
        statusCode: 401,
      );
    }
  }
}

final playersRepositoryProvider = Provider<PlayersRepository>((ref) {
  return PlayersRepository(ref.watch(apiClientProvider));
});
