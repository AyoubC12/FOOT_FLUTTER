import 'package:flutter/material.dart';

import 'preview_models.dart';

/// Hard-coded UI previews. Replace with repository mappers when the API is wired.
abstract final class PreviewCatalog {
  static const userName = 'Ayoub';

  static const leagues = <PreviewLeague>[
    PreviewLeague(id: 'pl', name: 'Premier League', country: 'England'),
    PreviewLeague(id: 'll', name: 'La Liga', country: 'Spain'),
    PreviewLeague(id: 'sa', name: 'Serie A', country: 'Italy'),
    PreviewLeague(id: 'bl', name: 'Bundesliga', country: 'Germany'),
    PreviewLeague(id: 'fl', name: 'Ligue 1', country: 'France'),
    PreviewLeague(id: 'ucl', name: 'Champions League', country: 'Europe'),
  ];

  static const teams = <PreviewTeam>[
    PreviewTeam(
      id: 'ars',
      name: 'Arsenal',
      shortName: 'ARS',
      color: Color(0xFFEF0107),
    ),
    PreviewTeam(
      id: 'liv',
      name: 'Liverpool',
      shortName: 'LIV',
      color: Color(0xFFC8102E),
    ),
    PreviewTeam(
      id: 'mci',
      name: 'Man City',
      shortName: 'MCI',
      color: Color(0xFF6CABDD),
    ),
    PreviewTeam(
      id: 'rma',
      name: 'Real Madrid',
      shortName: 'RMA',
      color: Color(0xFFFFFFFF),
    ),
    PreviewTeam(
      id: 'bar',
      name: 'Barcelona',
      shortName: 'BAR',
      color: Color(0xFFA50044),
    ),
    PreviewTeam(
      id: 'bay',
      name: 'Bayern',
      shortName: 'BAY',
      color: Color(0xFFDC052D),
    ),
    PreviewTeam(
      id: 'psg',
      name: 'Paris SG',
      shortName: 'PSG',
      color: Color(0xFF004170),
    ),
    PreviewTeam(
      id: 'int',
      name: 'Inter',
      shortName: 'INT',
      color: Color(0xFF010E80),
    ),
    PreviewTeam(
      id: 'che',
      name: 'Chelsea',
      shortName: 'CHE',
      color: Color(0xFF034694),
    ),
    PreviewTeam(
      id: 'nap',
      name: 'Napoli',
      shortName: 'NAP',
      color: Color(0xFF12A0D7),
    ),
  ];

  static const matches = <PreviewMatch>[
    PreviewMatch(
      id: 'm-live-1',
      leagueId: 'pl',
      homeId: 'ars',
      awayId: 'liv',
      kickoffLabel: 'Live · 67’',
      venue: 'Emirates Stadium',
      status: PreviewMatchStatus.live,
      homeScore: 1,
      awayScore: 1,
      minute: 67,
      homeWinPct: 38,
      drawPct: 28,
      awayWinPct: 34,
      stats: PreviewMatchStats(
        possessionHome: 57,
        shotsHome: 12,
        shotsAway: 9,
        xgHome: 1.42,
        xgAway: 1.18,
        cornersHome: 6,
        cornersAway: 4,
        passesHome: 482,
        passesAway: 401,
      ),
      headToHead: [
        PreviewH2H(label: 'Anfield 24/25', homeScore: 2, awayScore: 2),
        PreviewH2H(label: 'Emirates 23/24', homeScore: 3, awayScore: 1),
        PreviewH2H(label: 'Anfield 23/24', homeScore: 1, awayScore: 0),
      ],
    ),
    PreviewMatch(
      id: 'm-live-2',
      leagueId: 'll',
      homeId: 'bar',
      awayId: 'rma',
      kickoffLabel: 'Live · 12’',
      venue: 'Spotify Camp Nou',
      status: PreviewMatchStatus.live,
      homeScore: 0,
      awayScore: 0,
      minute: 12,
      homeWinPct: 41,
      drawPct: 26,
      awayWinPct: 33,
      stats: PreviewMatchStats(
        possessionHome: 61,
        shotsHome: 3,
        shotsAway: 1,
        xgHome: 0.31,
        xgAway: 0.08,
        cornersHome: 2,
        cornersAway: 0,
        passesHome: 118,
        passesAway: 91,
      ),
      headToHead: [
        PreviewH2H(label: 'Bernabéu 24/25', homeScore: 0, awayScore: 4),
        PreviewH2H(label: 'Montjuïc 23/24', homeScore: 1, awayScore: 2),
        PreviewH2H(label: 'Bernabéu 23/24', homeScore: 3, awayScore: 2),
      ],
    ),
    PreviewMatch(
      id: 'm-up-1',
      leagueId: 'ucl',
      homeId: 'mci',
      awayId: 'bay',
      kickoffLabel: 'Tue 20:00',
      venue: 'Etihad Stadium',
      status: PreviewMatchStatus.upcoming,
      homeWinPct: 46,
      drawPct: 25,
      awayWinPct: 29,
      stats: PreviewMatchStats(
        possessionHome: 58,
        shotsHome: 15,
        shotsAway: 11,
        xgHome: 1.9,
        xgAway: 1.4,
        cornersHome: 7,
        cornersAway: 5,
        passesHome: 620,
        passesAway: 510,
      ),
      headToHead: [
        PreviewH2H(label: 'UCL 22/23', homeScore: 3, awayScore: 0),
        PreviewH2H(label: 'UCL 22/23', homeScore: 1, awayScore: 1),
      ],
    ),
    PreviewMatch(
      id: 'm-up-2',
      leagueId: 'ucl',
      homeId: 'psg',
      awayId: 'int',
      kickoffLabel: 'Wed 21:00',
      venue: 'Parc des Princes',
      status: PreviewMatchStatus.upcoming,
      homeWinPct: 39,
      drawPct: 27,
      awayWinPct: 34,
      stats: PreviewMatchStats(
        possessionHome: 54,
        shotsHome: 13,
        shotsAway: 10,
        xgHome: 1.55,
        xgAway: 1.22,
        cornersHome: 5,
        cornersAway: 4,
        passesHome: 540,
        passesAway: 498,
      ),
      headToHead: [
        PreviewH2H(label: 'UCL 24/25', homeScore: 1, awayScore: 2),
      ],
    ),
    PreviewMatch(
      id: 'm-up-3',
      leagueId: 'pl',
      homeId: 'che',
      awayId: 'nap',
      kickoffLabel: 'Sat 17:30',
      venue: 'Stamford Bridge',
      status: PreviewMatchStatus.upcoming,
      homeWinPct: 44,
      drawPct: 29,
      awayWinPct: 27,
      stats: PreviewMatchStats(
        possessionHome: 52,
        shotsHome: 14,
        shotsAway: 9,
        xgHome: 1.6,
        xgAway: 1.1,
        cornersHome: 6,
        cornersAway: 3,
        passesHome: 501,
        passesAway: 455,
      ),
      headToHead: [
        PreviewH2H(label: 'Friendly 23', homeScore: 2, awayScore: 1),
      ],
    ),
    PreviewMatch(
      id: 'm-fin-1',
      leagueId: 'sa',
      homeId: 'int',
      awayId: 'nap',
      kickoffLabel: 'FT',
      venue: 'San Siro',
      status: PreviewMatchStatus.finished,
      homeScore: 2,
      awayScore: 0,
      homeWinPct: 62,
      drawPct: 22,
      awayWinPct: 16,
      stats: PreviewMatchStats(
        possessionHome: 49,
        shotsHome: 11,
        shotsAway: 8,
        xgHome: 1.88,
        xgAway: 0.74,
        cornersHome: 4,
        cornersAway: 5,
        passesHome: 433,
        passesAway: 451,
      ),
      headToHead: [
        PreviewH2H(label: 'Maradona 24/25', homeScore: 1, awayScore: 1),
        PreviewH2H(label: 'San Siro 23/24', homeScore: 1, awayScore: 1),
      ],
    ),
  ];

  static const players = <PreviewPlayer>[
    PreviewPlayer(
      id: 'saka',
      name: 'Bukayo Saka',
      clubId: 'ars',
      position: 'RW',
      nationality: 'England',
      number: 7,
      goals: 9,
      assists: 8,
      rating: 7.8,
      pace: 88,
      shooting: 82,
      passing: 84,
      dribbling: 89,
      defending: 58,
      physical: 72,
      form: [7.2, 7.6, 8.1, 7.4, 8.4, 7.9, 8.0],
    ),
    PreviewPlayer(
      id: 'salah',
      name: 'Mohamed Salah',
      clubId: 'liv',
      position: 'RW',
      nationality: 'Egypt',
      number: 11,
      goals: 14,
      assists: 9,
      rating: 8.1,
      pace: 90,
      shooting: 89,
      passing: 81,
      dribbling: 87,
      defending: 42,
      physical: 74,
      form: [8.4, 7.9, 8.6, 8.0, 7.7, 8.8, 8.2],
    ),
    PreviewPlayer(
      id: 'haaland',
      name: 'Erling Haaland',
      clubId: 'mci',
      position: 'ST',
      nationality: 'Norway',
      number: 9,
      goals: 18,
      assists: 3,
      rating: 8.0,
      pace: 89,
      shooting: 93,
      passing: 66,
      dribbling: 78,
      defending: 38,
      physical: 88,
      form: [8.8, 7.1, 8.5, 9.0, 7.6, 8.2, 8.4],
    ),
    PreviewPlayer(
      id: 'yamal',
      name: 'Lamine Yamal',
      clubId: 'bar',
      position: 'RW',
      nationality: 'Spain',
      number: 10,
      goals: 7,
      assists: 10,
      rating: 8.2,
      pace: 91,
      shooting: 78,
      passing: 86,
      dribbling: 92,
      defending: 36,
      physical: 62,
      form: [8.0, 8.3, 7.8, 8.6, 8.4, 8.1, 8.7],
    ),
    PreviewPlayer(
      id: 'bellingham',
      name: 'Jude Bellingham',
      clubId: 'rma',
      position: 'AM',
      nationality: 'England',
      number: 5,
      goals: 8,
      assists: 6,
      rating: 7.9,
      pace: 82,
      shooting: 80,
      passing: 85,
      dribbling: 86,
      defending: 74,
      physical: 84,
      form: [7.5, 8.2, 7.8, 8.0, 7.4, 8.3, 7.9],
    ),
    PreviewPlayer(
      id: 'mbappe',
      name: 'Kylian Mbappé',
      clubId: 'rma',
      position: 'ST',
      nationality: 'France',
      number: 9,
      goals: 16,
      assists: 5,
      rating: 8.3,
      pace: 97,
      shooting: 90,
      passing: 80,
      dribbling: 92,
      defending: 36,
      physical: 78,
      form: [8.6, 8.1, 7.9, 8.8, 8.4, 8.0, 8.7],
    ),
    PreviewPlayer(
      id: 'donna',
      name: 'Gianluigi Donnarumma',
      clubId: 'psg',
      position: 'GK',
      nationality: 'Italy',
      number: 1,
      goals: 0,
      assists: 0,
      rating: 7.2,
      pace: 52,
      shooting: 20,
      passing: 68,
      dribbling: 48,
      defending: 18,
      physical: 84,
      form: [7.0, 7.4, 6.8, 7.6, 7.1, 7.3, 7.5],
    ),
    PreviewPlayer(
      id: 'hakimi',
      name: 'Achraf Hakimi',
      clubId: 'psg',
      position: 'RB',
      nationality: 'Morocco',
      number: 2,
      goals: 3,
      assists: 6,
      rating: 7.6,
      pace: 93,
      shooting: 68,
      passing: 80,
      dribbling: 82,
      defending: 74,
      physical: 76,
      form: [7.4, 7.8, 7.2, 7.9, 7.5, 7.7, 7.6],
    ),
    PreviewPlayer(
      id: 'saliba',
      name: 'William Saliba',
      clubId: 'ars',
      position: 'CB',
      nationality: 'France',
      number: 2,
      goals: 2,
      assists: 1,
      rating: 7.5,
      pace: 82,
      shooting: 42,
      passing: 76,
      dribbling: 72,
      defending: 88,
      physical: 84,
      form: [7.6, 7.3, 7.8, 7.4, 7.7, 7.5, 7.9],
    ),
    PreviewPlayer(
      id: 'vvd',
      name: 'Virgil van Dijk',
      clubId: 'liv',
      position: 'CB',
      nationality: 'Netherlands',
      number: 4,
      goals: 3,
      assists: 2,
      rating: 7.7,
      pace: 76,
      shooting: 58,
      passing: 80,
      dribbling: 70,
      defending: 91,
      physical: 90,
      form: [7.8, 7.5, 7.9, 7.4, 8.0, 7.6, 7.7],
    ),
    PreviewPlayer(
      id: 'robertson',
      name: 'Andrew Robertson',
      clubId: 'liv',
      position: 'LB',
      nationality: 'Scotland',
      number: 26,
      goals: 1,
      assists: 7,
      rating: 7.3,
      pace: 84,
      shooting: 60,
      passing: 82,
      dribbling: 78,
      defending: 76,
      physical: 78,
      form: [7.1, 7.5, 7.2, 7.6, 7.0, 7.4, 7.3],
    ),
    PreviewPlayer(
      id: 'rice',
      name: 'Declan Rice',
      clubId: 'ars',
      position: 'CDM',
      nationality: 'England',
      number: 41,
      goals: 4,
      assists: 5,
      rating: 7.6,
      pace: 74,
      shooting: 72,
      passing: 82,
      dribbling: 78,
      defending: 86,
      physical: 86,
      form: [7.4, 7.8, 7.5, 7.9, 7.3, 7.7, 7.6],
    ),
    PreviewPlayer(
      id: 'pedri',
      name: 'Pedri',
      clubId: 'bar',
      position: 'CM',
      nationality: 'Spain',
      number: 8,
      goals: 5,
      assists: 7,
      rating: 7.8,
      pace: 76,
      shooting: 74,
      passing: 90,
      dribbling: 88,
      defending: 64,
      physical: 62,
      form: [7.9, 8.1, 7.6, 8.0, 7.7, 8.2, 7.8],
    ),
  ];

  /// Preview 4-3-3 from back to front. Unique IDs so pitch selection works.
  static const startingXiIds = <String>[
    'donna',
    'hakimi',
    'saliba',
    'vvd',
    'robertson',
    'rice',
    'pedri',
    'bellingham',
    'saka',
    'haaland',
    'yamal',
  ];

  static const suggestedPrompts = <String>[
    'Who wins Arsenal vs Liverpool?',
    'Explain City’s xG trend',
    'Best RW in Europe right now?',
    'How does a 4-3-3 press?',
  ];

  static const formations = <String>['4-3-3', '4-4-2', '4-2-3-1', '3-5-2'];

  static PreviewTeam teamById(String id) =>
      teams.firstWhere((team) => team.id == id, orElse: () => teams.first);

  static PreviewLeague leagueById(String id) => leagues.firstWhere(
    (league) => league.id == id,
    orElse: () => leagues.first,
  );

  static PreviewMatch matchById(String id) => matches.firstWhere(
    (match) => match.id == id,
    orElse: () => matches.first,
  );

  static PreviewPlayer playerById(String id) => players.firstWhere(
    (player) => player.id == id,
    orElse: () => players.first,
  );

  static List<PreviewMatch> get liveMatches => matches
      .where((match) => match.status == PreviewMatchStatus.live)
      .toList();

  static List<PreviewMatch> get upcomingMatches => matches
      .where((match) => match.status == PreviewMatchStatus.upcoming)
      .toList();

  static List<PreviewPlayer> get startingXi =>
      startingXiIds.map(playerById).toList();

  static String replyFor(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('arsenal') || lower.contains('liverpool')) {
      return 'Preview model: Arsenal 38% · Draw 28% · Liverpool 34%. '
          'Territory leans Arsenal, but Liverpool’s chance quality stays live.';
    }
    if (lower.contains('xg') || lower.contains('city')) {
      return 'Preview trend: City’s rolling xG is 1.9 at home in Europe. '
          'This is sample UI copy, not a live model output.';
    }
    if (lower.contains('rw') || lower.contains('winger')) {
      return 'Preview ranking: Yamal, Saka and Salah lead wide creation. '
          'Open a player card to compare shooting and dribbling.';
    }
    if (lower.contains('4-3-3') || lower.contains('press')) {
      return 'A 4-3-3 press uses the front three to trap the centre-backs, '
          'with the 8s jumping onto the pivot. Open Tactics to move the pieces.';
    }
    return 'I can walk through matches, players and shape using preview data. '
        'Try a suggested question below — live answers arrive once the API is connected.';
  }
}
