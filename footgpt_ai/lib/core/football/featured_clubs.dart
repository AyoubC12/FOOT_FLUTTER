import '../network/api_paths.dart';
import '../../features/teams/domain/team_models.dart';

/// Identity cards for the clubs the product always surfaces.
/// Crests use the API-Football / API-Sports media CDN — never generated art.
abstract final class FeaturedClubs {
  static const clubs = <FeaturedClub>[
    FeaturedClub(
      id: 541,
      name: 'Real Madrid',
      country: 'Spain',
      league: 'La Liga',
      leagueId: 140,
      city: 'Madrid',
      founded: 1902,
      stadium: 'Santiago Bernabéu',
    ),
    FeaturedClub(
      id: 529,
      name: 'FC Barcelona',
      country: 'Spain',
      league: 'La Liga',
      leagueId: 140,
      city: 'Barcelona',
      founded: 1899,
      stadium: 'Spotify Camp Nou',
    ),
    FeaturedClub(
      id: 50,
      name: 'Manchester City',
      country: 'England',
      league: 'Premier League',
      leagueId: 39,
      city: 'Manchester',
      founded: 1880,
      stadium: 'Etihad Stadium',
    ),
    FeaturedClub(
      id: 33,
      name: 'Manchester United',
      country: 'England',
      league: 'Premier League',
      leagueId: 39,
      city: 'Manchester',
      founded: 1878,
      stadium: 'Old Trafford',
    ),
    FeaturedClub(
      id: 40,
      name: 'Liverpool',
      country: 'England',
      league: 'Premier League',
      leagueId: 39,
      city: 'Liverpool',
      founded: 1892,
      stadium: 'Anfield',
    ),
    FeaturedClub(
      id: 42,
      name: 'Arsenal',
      country: 'England',
      league: 'Premier League',
      leagueId: 39,
      city: 'London',
      founded: 1886,
      stadium: 'Emirates Stadium',
    ),
    FeaturedClub(
      id: 49,
      name: 'Chelsea',
      country: 'England',
      league: 'Premier League',
      leagueId: 39,
      city: 'London',
      founded: 1905,
      stadium: 'Stamford Bridge',
    ),
    FeaturedClub(
      id: 157,
      name: 'Bayern Munich',
      country: 'Germany',
      league: 'Bundesliga',
      leagueId: 78,
      city: 'Munich',
      founded: 1900,
      stadium: 'Allianz Arena',
    ),
    FeaturedClub(
      id: 165,
      name: 'Borussia Dortmund',
      country: 'Germany',
      league: 'Bundesliga',
      leagueId: 78,
      city: 'Dortmund',
      founded: 1909,
      stadium: 'Signal Iduna Park',
    ),
    FeaturedClub(
      id: 85,
      name: 'Paris Saint-Germain',
      country: 'France',
      league: 'Ligue 1',
      leagueId: 61,
      city: 'Paris',
      founded: 1970,
      stadium: 'Parc des Princes',
    ),
    FeaturedClub(
      id: 496,
      name: 'Juventus',
      country: 'Italy',
      league: 'Serie A',
      leagueId: 135,
      city: 'Turin',
      founded: 1897,
      stadium: 'Allianz Stadium',
    ),
    FeaturedClub(
      id: 505,
      name: 'Inter Milan',
      country: 'Italy',
      league: 'Serie A',
      leagueId: 135,
      city: 'Milan',
      founded: 1908,
      stadium: 'San Siro',
    ),
    FeaturedClub(
      id: 489,
      name: 'AC Milan',
      country: 'Italy',
      league: 'Serie A',
      leagueId: 135,
      city: 'Milan',
      founded: 1899,
      stadium: 'San Siro',
    ),
    FeaturedClub(
      id: 973,
      name: 'Wydad AC',
      country: 'Morocco',
      league: 'Botola Pro',
      leagueId: 200,
      city: 'Casablanca',
      founded: 1937,
      stadium: 'Stade Mohammed V',
    ),
    FeaturedClub(
      id: 967,
      name: 'Raja CA',
      country: 'Morocco',
      league: 'Botola Pro',
      leagueId: 200,
      city: 'Casablanca',
      founded: 1949,
      stadium: 'Stade Mohammed V',
    ),
  ];

  static const competitions = <FeaturedCompetition>[
    FeaturedCompetition(id: 39, name: 'Premier League', country: 'England'),
    FeaturedCompetition(id: 140, name: 'La Liga', country: 'Spain'),
    FeaturedCompetition(id: 135, name: 'Serie A', country: 'Italy'),
    FeaturedCompetition(id: 78, name: 'Bundesliga', country: 'Germany'),
    FeaturedCompetition(id: 61, name: 'Ligue 1', country: 'France'),
    FeaturedCompetition(id: 2, name: 'Champions League', country: 'Europe'),
    FeaturedCompetition(id: 200, name: 'Botola Pro', country: 'Morocco'),
  ];

  static FeaturedClub? byId(int id) {
    for (final club in clubs) {
      if (club.id == id) return club;
    }
    return null;
  }
}

class FeaturedClub {
  const FeaturedClub({
    required this.id,
    required this.name,
    required this.country,
    required this.league,
    required this.leagueId,
    required this.city,
    this.founded,
    this.stadium,
  });

  final int id;
  final String name;
  final String country;
  final String league;
  final int leagueId;
  final String city;
  final int? founded;
  final String? stadium;

  String get logo => ApiPaths.providerTeamLogo(id);

  FootballClub toClub() {
    return FootballClub(
      id: id,
      name: name,
      country: country,
      city: city,
      founded: founded,
      logo: logo,
      stadiumName: stadium,
      leagueName: league,
      leagueId: leagueId,
    );
  }
}

class FeaturedCompetition {
  const FeaturedCompetition({
    required this.id,
    required this.name,
    required this.country,
  });

  final int id;
  final String name;
  final String country;

  String get logo => ApiPaths.providerLeagueLogo(id);
}
