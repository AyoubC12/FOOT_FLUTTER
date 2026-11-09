import 'package:flutter/material.dart';

import 'pitch_player.dart';

class FormationSlot {
  const FormationSlot({
    required this.position,
    required this.x,
    required this.y,
  });

  final String position;
  final double x;
  final double y;
}

abstract final class FormationTemplates {
  static const names = <String>['4-3-3', '4-4-2', '3-5-2', '4-2-3-1'];

  static const _fourThreeThree = <FormationSlot>[
    FormationSlot(position: 'GK', x: 0.50, y: 0.90),
    FormationSlot(position: 'LB', x: 0.14, y: 0.74),
    FormationSlot(position: 'LCB', x: 0.38, y: 0.76),
    FormationSlot(position: 'RCB', x: 0.62, y: 0.76),
    FormationSlot(position: 'RB', x: 0.86, y: 0.74),
    FormationSlot(position: 'LCM', x: 0.28, y: 0.52),
    FormationSlot(position: 'CDM', x: 0.50, y: 0.54),
    FormationSlot(position: 'RCM', x: 0.72, y: 0.52),
    FormationSlot(position: 'LW', x: 0.16, y: 0.28),
    FormationSlot(position: 'ST', x: 0.50, y: 0.22),
    FormationSlot(position: 'RW', x: 0.84, y: 0.28),
  ];

  static const _fourFourTwo = <FormationSlot>[
    FormationSlot(position: 'GK', x: 0.50, y: 0.90),
    FormationSlot(position: 'LB', x: 0.14, y: 0.74),
    FormationSlot(position: 'LCB', x: 0.38, y: 0.76),
    FormationSlot(position: 'RCB', x: 0.62, y: 0.76),
    FormationSlot(position: 'RB', x: 0.86, y: 0.74),
    FormationSlot(position: 'LM', x: 0.14, y: 0.48),
    FormationSlot(position: 'LCM', x: 0.38, y: 0.50),
    FormationSlot(position: 'RCM', x: 0.62, y: 0.50),
    FormationSlot(position: 'RM', x: 0.86, y: 0.48),
    FormationSlot(position: 'LST', x: 0.38, y: 0.22),
    FormationSlot(position: 'RST', x: 0.62, y: 0.22),
  ];

  static const _threeFiveTwo = <FormationSlot>[
    FormationSlot(position: 'GK', x: 0.50, y: 0.90),
    FormationSlot(position: 'LCB', x: 0.24, y: 0.74),
    FormationSlot(position: 'CB', x: 0.50, y: 0.76),
    FormationSlot(position: 'RCB', x: 0.76, y: 0.74),
    FormationSlot(position: 'LWB', x: 0.10, y: 0.52),
    FormationSlot(position: 'LCM', x: 0.34, y: 0.56),
    FormationSlot(position: 'CDM', x: 0.50, y: 0.50),
    FormationSlot(position: 'RCM', x: 0.66, y: 0.56),
    FormationSlot(position: 'RWB', x: 0.90, y: 0.52),
    FormationSlot(position: 'LST', x: 0.38, y: 0.24),
    FormationSlot(position: 'RST', x: 0.62, y: 0.24),
  ];

  static const _fourTwoThreeOne = <FormationSlot>[
    FormationSlot(position: 'GK', x: 0.50, y: 0.90),
    FormationSlot(position: 'LB', x: 0.14, y: 0.74),
    FormationSlot(position: 'LCB', x: 0.38, y: 0.76),
    FormationSlot(position: 'RCB', x: 0.62, y: 0.76),
    FormationSlot(position: 'RB', x: 0.86, y: 0.74),
    FormationSlot(position: 'LDM', x: 0.35, y: 0.58),
    FormationSlot(position: 'RDM', x: 0.65, y: 0.58),
    FormationSlot(position: 'LAM', x: 0.18, y: 0.40),
    FormationSlot(position: 'CAM', x: 0.50, y: 0.42),
    FormationSlot(position: 'RAM', x: 0.82, y: 0.40),
    FormationSlot(position: 'ST', x: 0.50, y: 0.22),
  ];

  static List<FormationSlot> slotsFor(String formation) {
    return switch (formation) {
      '4-4-2' => _fourFourTwo,
      '3-5-2' => _threeFiveTwo,
      '4-2-3-1' => _fourTwoThreeOne,
      _ => _fourThreeThree,
    };
  }

  static List<Offset> spotsFor(String formation) {
    return slotsFor(formation).map((slot) => Offset(slot.x, slot.y)).toList();
  }

  static List<PitchPlayer> lineup({
    required String formation,
    required List<PitchPlayer> roster,
  }) {
    final slots = slotsFor(formation);
    return [
      for (var i = 0; i < slots.length && i < roster.length; i++)
        roster[i].copyWith(
          position: slots[i].position,
          x: slots[i].x,
          y: slots[i].y,
        ),
    ];
  }

  static List<PitchPlayer> applyShape({
    required String formation,
    required List<PitchPlayer> players,
  }) {
    final slots = slotsFor(formation);
    return [
      for (var i = 0; i < players.length; i++)
        i < slots.length
            ? players[i].copyWith(
                position: slots[i].position,
                x: slots[i].x,
                y: slots[i].y,
              )
            : players[i],
    ];
  }
}
