import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/core/football/player_models.dart';

void main() {
  test('null provider stats stay null in comparison rows', () {
    final row = ComparisonRow.fromJson({
      'key': 'assists',
      'label': 'Assists',
      'left': 4,
      'right': null,
      'winner': null,
    });
    expect(row.left, 4);
    expect(row.right, isNull);
    expect(row.bothAvailable, isFalse);
  });

  test('player detail maps metrics without filling missing values', () {
    final detail = FootballPlayerDetail.fromJson({
      'id': 42,
      'name': 'Bukayo Saka',
      'age': 23,
      'nationality': 'England',
      'photo': null,
      'metrics': {'goals': 9, 'assists': null, 'tackles': 12},
      'primary': {
        'games': {'position': 'Attacker', 'number': 7},
        'team': {'name': 'Arsenal'},
        'league': {'name': 'Premier League'},
      },
      'statistics': [],
    });
    expect(detail.player.name, 'Bukayo Saka');
    expect(detail.metrics['goals'], 9);
    expect(detail.metrics['assists'], isNull);
    expect(detail.player.teamName, 'Arsenal');
  });
}
