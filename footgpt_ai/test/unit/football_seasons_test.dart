import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/core/football/football_seasons.dart';
import 'package:footgpt_ai/core/network/api_paths.dart';

void main() {
  test('football seasons cover 2009-2010 through 2026-2027', () {
    expect(FootballSeasons.years(descending: false).first, 2009);
    expect(FootballSeasons.years(descending: false).last, 2026);
    expect(FootballSeasons.label(2009), '2009-2010');
    expect(FootballSeasons.isComplete(FootballSeasons.currentStartYear), isFalse);
  });

  test('catalog paths stay versioned', () {
    expect(ApiPaths.footballCompetitions, '/api/v1/football/competitions/');
    expect(ApiPaths.teamSeasons(42), '/api/v1/football/teams/42/seasons/');
  });
}
