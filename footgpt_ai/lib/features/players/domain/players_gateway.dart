import '../../../core/football/player_models.dart';

/// Player analysis is served by Django (API-Football proxy). No provider keys here.
abstract interface class PlayersGateway {
  Future<List<FootballPlayer>> search({
    required String query,
    required int season,
    int? teamId,
  });

  Future<FootballPlayerDetail> statistics({
    required int playerId,
    required int season,
  });

  Future<PlayerComparisonResult> compare({
    required int leftId,
    required int rightId,
    required int season,
  });
}
