import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../football/player_models.dart';

class PlayerRadarChart extends StatelessWidget {
  const PlayerRadarChart({super.key, required this.rows});

  final List<ComparisonRow> rows;

  @override
  Widget build(BuildContext context) {
    final usable = rows.where((row) => row.bothAvailable).take(8).toList();
    if (usable.length < 3) {
      return const Text(
        'Not enough shared statistics for a radar chart.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    return SizedBox(
      height: 260,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 3,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          radarBorderData: const BorderSide(color: AppColors.border),
          gridBorderData: const BorderSide(color: AppColors.border),
          titleTextStyle: const TextStyle(color: AppColors.muted, fontSize: 11),
          getTitle: (index, _) => RadarChartTitle(text: usable[index].label),
          dataSets: [
            RadarDataSet(
              fillColor: AppColors.accent.withValues(alpha: 0.18),
              borderColor: AppColors.accent,
              entryRadius: 2,
              dataEntries: [
                for (final row in usable)
                  RadarEntry(value: _scaled(row.left!, row.right!)),
              ],
            ),
            RadarDataSet(
              fillColor: AppColors.info.withValues(alpha: 0.12),
              borderColor: AppColors.info,
              entryRadius: 2,
              dataEntries: [
                for (final row in usable)
                  RadarEntry(value: _scaled(row.right!, row.left!)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _scaled(num value, num other) {
    final maxValue = value > other ? value : other;
    if (maxValue == 0) return 0;
    return value / maxValue;
  }
}
