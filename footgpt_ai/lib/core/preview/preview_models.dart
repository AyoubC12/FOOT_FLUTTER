import 'package:flutter/material.dart';

/// UI preview models only. Do not send these to a backend or treat them as live data.
class PreviewTeam {
  const PreviewTeam({
    required this.id,
    required this.name,
    required this.shortName,
    required this.color,
  });

  final String id;
  final String name;
  final String shortName;
  final Color color;
}

class PreviewLeague {
  const PreviewLeague({
    required this.id,
    required this.name,
    required this.country,
  });

  final String id;
  final String name;
  final String country;
}

enum PreviewMatchStatus { live, upcoming, finished }

class PreviewMatch {
  const PreviewMatch({
    required this.id,
    required this.leagueId,
    required this.homeId,
    required this.awayId,
    required this.kickoffLabel,
    required this.venue,
    required this.status,
    this.homeScore,
    this.awayScore,
    this.minute,
    required this.homeWinPct,
    required this.drawPct,
    required this.awayWinPct,
    required this.stats,
    required this.headToHead,
  });

  final String id;
  final String leagueId;
  final String homeId;
  final String awayId;
  final String kickoffLabel;
  final String venue;
  final PreviewMatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final int? minute;
  final int homeWinPct;
  final int drawPct;
  final int awayWinPct;
  final PreviewMatchStats stats;
  final List<PreviewH2H> headToHead;
}

class PreviewMatchStats {
  const PreviewMatchStats({
    required this.possessionHome,
    required this.shotsHome,
    required this.shotsAway,
    required this.xgHome,
    required this.xgAway,
    required this.cornersHome,
    required this.cornersAway,
    required this.passesHome,
    required this.passesAway,
  });

  final int possessionHome;
  int get possessionAway => 100 - possessionHome;
  final int shotsHome;
  final int shotsAway;
  final double xgHome;
  final double xgAway;
  final int cornersHome;
  final int cornersAway;
  final int passesHome;
  final int passesAway;
}

class PreviewH2H {
  const PreviewH2H({
    required this.label,
    required this.homeScore,
    required this.awayScore,
  });

  final String label;
  final int homeScore;
  final int awayScore;
}

class PreviewPlayer {
  const PreviewPlayer({
    required this.id,
    required this.name,
    required this.clubId,
    required this.position,
    required this.nationality,
    required this.number,
    required this.goals,
    required this.assists,
    required this.rating,
    required this.pace,
    required this.shooting,
    required this.passing,
    required this.dribbling,
    required this.defending,
    required this.physical,
    required this.form,
  });

  final String id;
  final String name;
  final String clubId;
  final String position;
  final String nationality;
  final int number;
  final int goals;
  final int assists;
  final double rating;
  final int pace;
  final int shooting;
  final int passing;
  final int dribbling;
  final int defending;
  final int physical;
  final List<double> form;

  String get initials {
    return name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join();
  }
}

class PreviewChatMessage {
  const PreviewChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}
