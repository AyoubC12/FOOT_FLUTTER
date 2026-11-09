abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/dashboard';
  static const matches = '/matches';
  static const matchDetails = '/match/:matchId';
  static const predictions = '/predictions';
  static const stats = '/stats';
  static const teams = '/teams';
  static const teamDetails = '/team/:teamId';
  static const teamCompare = '/teams/compare';
  static const players = '/players';
  static const playerDetails = '/player/:playerId';
  static const playerCompare = '/compare';
  static const tactics = '/tactics';
  static const chatbot = '/chatbot';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const settings = '/settings';

  static String teamDetailsPath(String teamId, {String? league}) {
    if (league == null || league.isEmpty) return '/team/$teamId';
    return Uri(path: '/team/$teamId', queryParameters: {'league': league}).toString();
  }
  static String matchDetailsPath(String matchId) => '/match/$matchId';
  static String playerDetailsPath(String playerId) => '/player/$playerId';
  static String comparePath({String? left, String? right}) {
    final params = <String, String>{
      'left': ?left,
      'right': ?right,
    };
    if (params.isEmpty) return playerCompare;
    return Uri(path: playerCompare, queryParameters: params).toString();
  }
}
