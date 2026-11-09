// ignore_for_file: use_null_aware_elements

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_paths.dart';

class MatchEstimate {
  const MatchEstimate({
    required this.homePct,
    required this.drawPct,
    required this.awayPct,
    this.explanation,
    this.disclaimer,
    this.modelName,
    this.dataQuality,
  });

  final double homePct;
  final double drawPct;
  final double awayPct;
  final String? explanation;
  final String? disclaimer;
  final String? modelName;
  final String? dataQuality;
}

class PredictionsRepository {
  PredictionsRepository(this._client);

  final ApiClient _client;

  Future<MatchEstimate> estimate({
    required int homeId,
    required int awayId,
    required String homeName,
    required String awayName,
    int? leagueId,
    int? season,
  }) async {
    if (!_client.hasBaseUrl) {
      throw const ApiException(
        'Connect Django to compute probabilistic estimates. Nothing here is a guaranteed result.',
      );
    }
    final token = await _client.tokens.readAccess();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Sign in to run a prediction through Django.',
        statusCode: 401,
      );
    }
    final response = await _client.post<Map<String, dynamic>>(
      ApiPaths.predictionEstimate,
      data: {
        'home_team_id': homeId,
        'away_team_id': awayId,
        'home_team': homeName,
        'away_team': awayName,
        if (leagueId != null) 'league_id': leagueId,
        // ignore: use_null_aware_elements
        if (season != null) 'season': season,
      },
    );
    final data = response.data ?? const {};
    final probs = data['probabilities'];
    if (probs is! Map) {
      throw const ApiException('The backend did not return probabilities.');
    }
    return MatchEstimate(
      homePct: (probs['home'] as num?)?.toDouble() ?? 0,
      drawPct: (probs['draw'] as num?)?.toDouble() ?? 0,
      awayPct: (probs['away'] as num?)?.toDouble() ?? 0,
      explanation: data['explanation'] as String?,
      disclaimer: data['disclaimer'] as String? ??
          'This is a probabilistic estimate, not a guaranteed outcome.',
      modelName: data['model_name'] as String?,
      dataQuality: data['data_quality'] as String?,
    );
  }
}

final predictionsRepositoryProvider = Provider<PredictionsRepository>((ref) {
  return PredictionsRepository(ref.watch(apiClientProvider));
});
