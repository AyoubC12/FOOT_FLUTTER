class FootballCompetition {
  const FootballCompetition({
    required this.id,
    required this.name,
    this.country,
  });

  final String id;
  final String name;
  final String? country;

  factory FootballCompetition.fromJson(Map<String, dynamic> json) {
    return FootballCompetition(
      id: '${json['external_id'] ?? json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      country: json['country'] as String?,
    );
  }
}

class FootballClub {
  const FootballClub({
    required this.id,
    required this.name,
    this.code,
    this.country,
    this.city,
    this.founded,
    this.website,
    this.coachName,
    this.logo,
    this.stadiumName,
    this.stadiumCapacity,
    this.leagueName,
    this.leagueId,
  });

  final int id;
  final String name;
  final String? code;
  final String? country;
  final String? city;
  final int? founded;
  final String? website;
  final String? coachName;
  final String? logo;
  final String? stadiumName;
  final int? stadiumCapacity;
  final String? leagueName;
  final int? leagueId;

  factory FootballClub.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'];
    return FootballClub(
      id: json['id'] as int? ?? 0,
      name: '${json['name'] ?? ''}',
      code: json['code'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String? ??
          (venue is Map ? venue['city'] as String? : null),
      founded: json['founded'] as int?,
      website: json['website'] as String?,
      coachName: json['coach_name'] as String?,
      logo: json['logo'] as String?,
      stadiumName: venue is Map ? venue['name'] as String? : json['stadium_name'] as String?,
      stadiumCapacity: venue is Map
          ? venue['capacity'] as int?
          : json['stadium_capacity'] as int?,
      leagueName: json['league_name'] as String?,
      leagueId: json['league_id'] as int?,
    );
  }
}

class TeamSeasonRow {
  const TeamSeasonRow({
    required this.year,
    required this.label,
    required this.isComplete,
    this.competitionName,
    this.played,
    this.wins,
    this.draws,
    this.losses,
    this.goalsFor,
    this.goalsAgainst,
    this.goalDiff,
    this.points,
    this.rank,
    this.cleanSheets,
    this.possessionAvg,
    this.shotsPerGame,
    this.missingFields = const [],
  });

  final int year;
  final String label;
  final bool isComplete;
  final String? competitionName;
  final int? played;
  final int? wins;
  final int? draws;
  final int? losses;
  final int? goalsFor;
  final int? goalsAgainst;
  final int? goalDiff;
  final int? points;
  final int? rank;
  final int? cleanSheets;
  final num? possessionAvg;
  final num? shotsPerGame;
  final List<String> missingFields;

  factory TeamSeasonRow.fromJson(Map<String, dynamic> json) {
    return TeamSeasonRow(
      year: json['year'] as int? ?? 0,
      label: '${json['label'] ?? json['year']}',
      isComplete: json['is_complete'] == true,
      competitionName: json['competition_name'] as String?,
      played: json['played'] as int?,
      wins: json['wins'] as int?,
      draws: json['draws'] as int?,
      losses: json['losses'] as int?,
      goalsFor: json['goals_for'] as int?,
      goalsAgainst: json['goals_against'] as int?,
      goalDiff: json['goal_diff'] as int?,
      points: json['points'] as int?,
      rank: json['rank'] as int?,
      cleanSheets: json['clean_sheets'] as int?,
      possessionAvg: json['possession_avg'] as num?,
      shotsPerGame: json['shots_per_game'] as num?,
      missingFields: [
        for (final item in json['missing_fields'] as List? ?? const []) '$item',
      ],
    );
  }
}
