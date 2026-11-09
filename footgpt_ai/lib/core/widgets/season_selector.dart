import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../football/football_seasons.dart';

class SeasonSelector extends StatelessWidget {
  const SeasonSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.fullHistory = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final bool fullHistory;

  static List<int> seasons({int? current}) {
    final year = current ?? FootballSeasons.currentStartYear;
    return [for (var i = 0; i < 5; i++) year - i];
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final season in fullHistory ? FootballSeasons.years() : seasons())
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child:               ChoiceChip(
                label: Text(
                  FootballSeasons.isComplete(season)
                      ? FootballSeasons.label(season)
                      : '${FootballSeasons.label(season)} · current',
                ),
                selected: season == value,
                selectedColor: AppColors.accentMuted,
                labelStyle: TextStyle(
                  color: season == value ? AppColors.accent : AppColors.white,
                ),
                onSelected: (_) => onChanged(season),
              ),
            ),
        ],
      ),
    );
  }
}
