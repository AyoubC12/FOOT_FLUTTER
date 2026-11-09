import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/football/player_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';
import '../domain/team_models.dart';

class TeamsRepository {
  TeamsRepository(this._client);

  final ApiClient _client;

  Future<List<FootballCompetition>> competitions() async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.footballCompetitions,
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => FootballCompetition.fromJson(item as Map<String, dynamic>))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  Future<List<FootballClub>> list({
    required int leagueId,
    required int season,
    String? search,
    String? country,
  }) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.footballTeams,
      queryParameters: {
        'league': leagueId,
        'season': season,
      },
    );
    final results = (response.data?['results'] as List?) ?? const [];
    var clubs = results
        .map((item) => FootballClub.fromJson(item as Map<String, dynamic>))
        .where((club) => club.id > 0 && club.name.isNotEmpty)
        .toList();
    if (search != null && search.trim().isNotEmpty) {
      final needle = search.trim().toLowerCase();
      clubs = clubs
          .where((club) => club.name.toLowerCase().contains(needle))
          .toList();
    }
    if (country != null && country.trim().isNotEmpty) {
      final needle = country.trim().toLowerCase();
      clubs = clubs
          .where((club) => (club.country ?? '').toLowerCase() == needle)
          .toList();
    }
    return clubs;
  }

  Future<FootballClub> detail(int teamId) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.teamDetail(teamId),
    );
    final results = response.data?['results'];
    if (results is! Map<String, dynamic> || results['id'] == null) {
      throw const ApiException('No verified club record was returned.');
    }
    return FootballClub.fromJson(results);
  }

  Future<List<TeamSeasonRow>> seasons(int teamId, {int? leagueId}) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.teamSeasons(teamId),
      queryParameters: {
        'league': ?leagueId,
      },
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => TeamSeasonRow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<FootballPlayer>> squad(int teamId) async {
    _requireApi();
    await _requireAuth();
    final response = await _client.get<Map<String, dynamic>>(
      ApiPaths.teamSquad(teamId),
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return results
        .map((item) => FootballPlayer.fromJson(item as Map<String, dynamic>))
        .where((player) => player.id > 0)
        .toList();
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
        'Sign in to load API-Football clubs.',
        statusCode: 401,
      );
    }
  }
}

final teamsRepositoryProvider = Provider<TeamsRepository>((ref) {
  return TeamsRepository(ref.watch(apiClientProvider));
});
