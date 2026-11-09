import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../football/football_seasons.dart';

class SeasonPoint {
  const SeasonPoint({required this.year, required this.value});

  final int year;
  final num value;
}

class HistoryChart extends StatelessWidget {
  const HistoryChart({super.key, required this.points, this.invertY = false});

  final List<SeasonPoint> points;
  final bool invertY;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const Text(
        'Not enough verified season values to draw a chart.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].value.toDouble()),
    ];
    final ys = spots.map((spot) => spot.y);
    final minY = invertY ? ys.reduce((a, b) => a < b ? a : b) : 0;
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: invertY ? minY - 1 : 0,
          maxY: maxY + 1,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.round();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return Text(
                    FootballSeasons.label(points[index].year).substring(2, 7),
                    style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: AppColors.accent,
              barWidth: 2.4,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}
