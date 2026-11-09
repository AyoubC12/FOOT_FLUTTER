class FootballPlayer {
  const FootballPlayer({
    required this.id,
    required this.name,
    this.age,
    this.nationality,
    this.photo,
    this.position,
    this.number,
    this.teamName,
    this.teamLogo,
    this.leagueName,
    this.goals,
    this.assists,
    this.rating,
    this.appearances,
  });

  final int id;
  final String name;
  final int? age;
  final String? nationality;
  final String? photo;
  final String? position;
  final int? number;
  final String? teamName;
  final String? teamLogo;
  final String? leagueName;
  final num? goals;
  final num? assists;
  final num? rating;
  final num? appearances;

  String get initials {
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  factory FootballPlayer.fromJson(Map<String, dynamic> json) {
    final team = json['team'];
    final league = json['league'];
    return FootballPlayer(
      id: json['id'] as int? ?? 0,
      name: '${json['name'] ?? 'Unknown'}',
      age: json['age'] as int?,
      nationality: json['nationality'] as String?,
      photo: json['photo'] as String?,
      position: json['position'] as String?,
      number: json['number'] as int?,
      teamName: team is Map ? team['name'] as String? : null,
      teamLogo: team is Map ? team['logo'] as String? : null,
      leagueName: league is Map ? league['name'] as String? : null,
      goals: json['goals'] as num?,
      assists: json['assists'] as num?,
      rating: _num(json['rating']),
      appearances: json['appearances'] as num?,
    );
  }
}

class FootballPlayerDetail {
  const FootballPlayerDetail({
    required this.player,
    required this.metrics,
    required this.leagues,
    this.height,
    this.weight,
    this.injured,
  });

  final FootballPlayer player;
  final Map<String, num?> metrics;
  final List<Map<String, dynamic>> leagues;
  final String? height;
  final String? weight;
  final bool? injured;

  factory FootballPlayerDetail.fromJson(Map<String, dynamic> json) {
    final primary = json['primary'] as Map<String, dynamic>? ?? {};
    final games = primary['games'] as Map<String, dynamic>? ?? {};
    final team = primary['team'];
    final league = primary['league'];
    final metricsRaw = json['metrics'] as Map<String, dynamic>? ?? {};
    final metrics = <String, num?>{
      for (final entry in metricsRaw.entries) entry.key: _num(entry.value),
    };
    return FootballPlayerDetail(
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      injured: json['injured'] as bool?,
      leagues: (json['statistics'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      metrics: metrics,
      player: FootballPlayer(
        id: json['id'] as int? ?? 0,
        name: '${json['name'] ?? 'Unknown'}',
        age: json['age'] as int?,
        nationality: json['nationality'] as String?,
        photo: json['photo'] as String?,
        position: (games['position'] ?? json['position']) as String?,
        number: games['number'] as int? ?? json['number'] as int?,
        teamName: team is Map ? team['name'] as String? : null,
        teamLogo: team is Map ? team['logo'] as String? : null,
        leagueName: league is Map ? league['name'] as String? : null,
        goals: metrics['goals'],
        assists: metrics['assists'],
        rating: metrics['rating'],
        appearances: metrics['appearances'],
      ),
    );
  }
}

class ComparisonRow {
  const ComparisonRow({
    required this.keyName,
    required this.label,
    this.left,
    this.right,
    this.winner,
  });

  final String keyName;
  final String label;
  final num? left;
  final num? right;
  final String? winner;

  bool get bothAvailable => left != null && right != null;

  factory ComparisonRow.fromJson(Map<String, dynamic> json) {
    return ComparisonRow(
      keyName: '${json['key']}',
      label: '${json['label']}',
      left: _num(json['left']),
      right: _num(json['right']),
      winner: json['winner'] as String?,
    );
  }
}

class PlayerComparisonResult {
  const PlayerComparisonResult({
    required this.season,
    required this.left,
    required this.right,
    required this.rows,
    required this.disclaimer,
  });

  final int season;
  final FootballPlayerDetail left;
  final FootballPlayerDetail right;
  final List<ComparisonRow> rows;
  final String disclaimer;

  factory PlayerComparisonResult.fromJson(Map<String, dynamic> json) {
    return PlayerComparisonResult(
      season: json['season'] as int? ?? 0,
      left: FootballPlayerDetail.fromJson(json['left'] as Map<String, dynamic>),
      right: FootballPlayerDetail.fromJson(json['right'] as Map<String, dynamic>),
      rows: (json['rows'] as List? ?? const [])
          .map((item) => ComparisonRow.fromJson(item as Map<String, dynamic>))
          .toList(),
      disclaimer: '${json['disclaimer'] ?? ''}',
    );
  }
}

class SavedComparison {
  const SavedComparison({
    required this.id,
    required this.season,
    required this.leftPlayerId,
    required this.rightPlayerId,
    required this.leftName,
    required this.rightName,
    this.leftPhoto,
    this.rightPhoto,
  });

  final int id;
  final int season;
  final int leftPlayerId;
  final int rightPlayerId;
  final String leftName;
  final String rightName;
  final String? leftPhoto;
  final String? rightPhoto;

  factory SavedComparison.fromJson(Map<String, dynamic> json) {
    return SavedComparison(
      id: json['id'] as int,
      season: json['season'] as int,
      leftPlayerId: json['left_player_id'] as int,
      rightPlayerId: json['right_player_id'] as int,
      leftName: '${json['left_name']}',
      rightName: '${json['right_name']}',
      leftPhoto: json['left_photo'] as String?,
      rightPhoto: json['right_photo'] as String?,
    );
  }
}

class PlayerSeasonRow {
  const PlayerSeasonRow({
    required this.year,
    required this.label,
    this.teamName,
    this.goals,
    this.assists,
    this.appearances,
    this.rating,
    this.missingFields = const [],
  });

  final int year;
  final String label;
  final String? teamName;
  final int? goals;
  final int? assists;
  final int? appearances;
  final num? rating;
  final List<String> missingFields;

  factory PlayerSeasonRow.fromJson(Map<String, dynamic> json) {
    return PlayerSeasonRow(
      year: json['year'] as int? ?? 0,
      label: '${json['label'] ?? json['year']}',
      teamName: json['team_name'] as String?,
      goals: json['goals'] as int?,
      assists: json['assists'] as int?,
      appearances: json['appearances'] as int?,
      rating: json['rating'] as num?,
      missingFields: [
        for (final item in json['missing_fields'] as List? ?? const []) '$item',
      ],
    );
  }
}

num? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse('$value');
}

const metricLabels = <String, String>{
  'appearances': 'Appearances',
  'minutes': 'Minutes',
  'rating': 'Rating',
  'goals': 'Goals',
  'assists': 'Assists',
  'shots': 'Shots',
  'shots_on': 'Shots on target',
  'passes': 'Passes',
  'key_passes': 'Key passes',
  'pass_accuracy': 'Pass accuracy',
  'tackles': 'Tackles',
  'interceptions': 'Interceptions',
  'blocks': 'Blocks',
  'duels_won': 'Duels won',
  'dribbles_success': 'Successful dribbles',
};
