class PitchPlayer {
  const PitchPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.x,
    required this.y,
    this.number,
  });

  final String id;
  final String name;
  final String position;
  final double x;
  final double y;
  final int? number;

  String get lastName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.last;
  }

  String get initials {
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();
  }

  PitchPlayer copyWith({
    String? name,
    String? position,
    double? x,
    double? y,
    int? number,
  }) {
    return PitchPlayer(
      id: id,
      name: name ?? this.name,
      position: position ?? this.position,
      x: x ?? this.x,
      y: y ?? this.y,
      number: number ?? this.number,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'x': x,
      'y': y,
      'number': ?number,
    };
  }

  factory PitchPlayer.fromJson(Map<String, dynamic> json) {
    return PitchPlayer(
      id: '${json['id']}',
      name: '${json['name'] ?? ''}',
      position: '${json['position'] ?? ''}',
      x: (json['x'] as num?)?.toDouble() ?? 0.5,
      y: (json['y'] as num?)?.toDouble() ?? 0.5,
      number: json['number'] as int?,
    );
  }
}

class TacticalBoardRecord {
  const TacticalBoardRecord({
    required this.id,
    required this.name,
    required this.formation,
    required this.players,
    this.notes = '',
  });

  final int id;
  final String name;
  final String formation;
  final List<PitchPlayer> players;
  final String notes;

  factory TacticalBoardRecord.fromJson(Map<String, dynamic> json) {
    final raw = json['players'] as List? ?? const [];
    return TacticalBoardRecord(
      id: json['id'] as int,
      name: '${json['name'] ?? ''}',
      formation: '${json['formation'] ?? ''}',
      notes: '${json['notes'] ?? ''}',
      players: raw
          .map((item) => PitchPlayer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
