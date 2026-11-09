class FootballFixture {
  const FootballFixture({
    required this.id,
    required this.statusShort,
    this.elapsed,
    this.date,
    this.leagueName,
    this.leagueLogo,
    this.leagueCountry,
    this.homeId,
    this.homeName,
    this.homeLogo,
    this.homeGoals,
    this.awayId,
    this.awayName,
    this.awayLogo,
    this.awayGoals,
    this.venue,
  });

  final int id;
  final String statusShort;
  final int? elapsed;
  final DateTime? date;
  final String? leagueName;
  final String? leagueLogo;
  final String? leagueCountry;
  final int? homeId;
  final String? homeName;
  final String? homeLogo;
  final int? homeGoals;
  final int? awayId;
  final String? awayName;
  final String? awayLogo;
  final int? awayGoals;
  final String? venue;

  bool get isLive {
    const live = {'1H', '2H', 'HT', 'ET', 'BT', 'P', 'LIVE', 'INT'};
    return live.contains(statusShort.toUpperCase());
  }

  bool get isFinished {
    const done = {'FT', 'AET', 'PEN', 'AWD', 'WO'};
    return done.contains(statusShort.toUpperCase());
  }

  bool get isUpcoming => !isLive && !isFinished;

  factory FootballFixture.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final league = json['league'];
    final teams = json['teams'];
    final goals = json['goals'];
    final venue = json['venue'];
    final home = teams is Map ? teams['home'] : null;
    final away = teams is Map ? teams['away'] : null;
    return FootballFixture(
      id: _asInt(json['id']) ?? 0,
      statusShort: status is Map
          ? '${status['short'] ?? ''}'
          : '${json['status'] ?? ''}',
      elapsed: status is Map ? _asInt(status['elapsed']) : _asInt(json['elapsed']),
      date: DateTime.tryParse('${json['date'] ?? ''}'),
      leagueName: league is Map ? league['name'] as String? : json['league_name'] as String?,
      leagueLogo: league is Map ? league['logo'] as String? : null,
      leagueCountry: league is Map ? league['country'] as String? : null,
      homeId: home is Map ? _asInt(home['id']) : null,
      homeName: home is Map ? home['name'] as String? : null,
      homeLogo: home is Map ? home['logo'] as String? : null,
      homeGoals: goals is Map ? _asInt(goals['home']) : _asInt(json['home_goals']),
      awayId: away is Map ? _asInt(away['id']) : null,
      awayName: away is Map ? away['name'] as String? : null,
      awayLogo: away is Map ? away['logo'] as String? : null,
      awayGoals: goals is Map ? _asInt(goals['away']) : _asInt(json['away_goals']),
      venue: venue is Map ? venue['name'] as String? : json['venue'] as String?,
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}
