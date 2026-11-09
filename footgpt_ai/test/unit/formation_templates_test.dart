import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/core/tactics/formation_templates.dart';
import 'package:footgpt_ai/core/tactics/pitch_player.dart';

void main() {
  test('every named formation has eleven slots', () {
    for (final name in FormationTemplates.names) {
      expect(FormationTemplates.slotsFor(name), hasLength(11));
    }
  });

  test('applyShape remaps existing players onto the new template', () {
    final roster = [
      for (var i = 0; i < 11; i++)
        PitchPlayer(
          id: 'p$i',
          name: 'Player $i',
          position: 'ST',
          x: 0.5,
          y: 0.5,
        ),
    ];
    final shaped = FormationTemplates.applyShape(
      formation: '4-4-2',
      players: roster,
    );
    expect(shaped, hasLength(11));
    expect(shaped.first.position, 'GK');
    expect(shaped.first.y, greaterThan(0.8));
    expect(shaped.last.position, 'RST');
  });

  test('PitchPlayer json round-trip keeps coordinates', () {
    const player = PitchPlayer(
      id: 'x',
      name: 'Saka',
      position: 'RW',
      x: 0.84,
      y: 0.28,
      number: 7,
    );
    final copy = PitchPlayer.fromJson(player.toJson());
    expect(copy.id, 'x');
    expect(copy.x, 0.84);
    expect(copy.number, 7);
  });
}
