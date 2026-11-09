/// Versioned Django routes. Secrets never belong here — only path suffixes.
abstract final class ApiPaths {
  static const prefix = '/api/v1';

  static const login = '$prefix/auth/login/';
  static const register = '$prefix/auth/register/';
  static const logout = '$prefix/auth/logout/';
  static const tokenRefresh = '$prefix/auth/token/refresh/';
  static const profile = '$prefix/auth/profile/';

  static const footballLive = '$prefix/football/fixtures/live/';
  static const footballFixtures = '$prefix/football/fixtures/';
  static const footballTeams = '$prefix/football/teams/';
  static const footballCatalogTeams = '$prefix/football/catalog/teams/';
  static const footballCompetitions = '$prefix/football/competitions/';
  static const footballStandings = '$prefix/football/standings/';
  static String teamDetail(int id) => '$prefix/football/teams/$id/';
  static String teamSeasons(int id) => '$prefix/football/teams/$id/seasons/';
  static String teamSquad(int id) => '$prefix/football/teams/$id/squad/';
  static String teamStatistics(int id) => '$prefix/football/teams/$id/statistics/';
  static String competitionSeasons(int id) =>
      '$prefix/football/competitions/$id/seasons/';
  static const footballTeamCompare = '$prefix/football/teams/compare/';
  static const footballPlayers = '$prefix/football/players/';
  static String playerDetail(int id) => '$prefix/football/players/$id/';
  static String playerSeasons(int id) => '$prefix/football/players/$id/seasons/';
  static String playerTransfers(int id) => '$prefix/football/players/$id/transfers/';
  static String playerStatistics(int id) =>
      '$prefix/football/players/$id/statistics/';
  static const playerCompare = '$prefix/football/players/compare/';
  static const playerComparisons = '$prefix/football/players/comparisons/';
  static String playerComparison(int id) =>
      '$prefix/football/players/comparisons/$id/';

  static const predictions = '$prefix/predictions/';
  static const predictionEstimate = '$prefix/predictions/estimate/';

  static const assistantChat = '$prefix/assistant/chat/';
  static const assistantMessages = '$prefix/assistant/messages/';
  static const assistantSuggestions = '$prefix/assistant/suggestions/';

  static const tacticBoards = '$prefix/tactics/boards/';
  static String tacticBoard(int id) => '$prefix/tactics/boards/$id/';
  static const tacticSuggest = '$prefix/tactics/suggest/';

  static const favorites = '$prefix/favorites/';
  static const notificationDevices = '$prefix/notifications/devices/';

  /// Public API-Sports media CDN. These are provider assets, not app-generated.
  static String providerTeamLogo(int id) =>
      'https://media.api-sports.io/football/teams/$id.png';
  static String providerLeagueLogo(int id) =>
      'https://media.api-sports.io/football/leagues/$id.png';
  static String providerPlayerPhoto(int id) =>
      'https://media.api-sports.io/football/players/$id.png';
}
