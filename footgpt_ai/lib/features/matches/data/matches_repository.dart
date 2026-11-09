import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/football/fixture_models.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';

class MatchesRepository {
  MatchesRepository(this._client);

  final ApiClient _client;

  Future<List<FootballFixture>> live() async {
    return _load(ApiPaths.footballLive);
  }

  Future<List<FootballFixture>> upcoming() async {
    return _load(
      ApiPaths.footballFixtures,
      query: const {'next': 20},
    );
  }

  Future<List<FootballFixture>> _load(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException(
        'Connect Django with --dart-define=API_BASE_URL=http://127.0.0.1:8000 to load fixtures.',
      );
    }
    final token = await _client.tokens.readAccess();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sign in to load live and upcoming fixtures from API-Football.',
        statusCode: 401,
      );
    }
    final response = await _client.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
    );
    final results = (response.data?['results'] as List?) ?? const [];
    return [
      for (final item in results)
        if (item is Map<String, dynamic>)
          FootballFixture.fromJson(item),
    ].where((fixture) => fixture.id > 0).toList();
  }
}

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(ref.watch(apiClientProvider));
});

final liveFixturesProvider = FutureProvider<List<FootballFixture>>((ref) {
  return ref.watch(matchesRepositoryProvider).live();
});

final upcomingFixturesProvider = FutureProvider<List<FootballFixture>>((ref) {
  return ref.watch(matchesRepositoryProvider).upcoming();
});
