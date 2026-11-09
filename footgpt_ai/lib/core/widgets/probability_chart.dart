import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class ProbabilityChart extends StatelessWidget {
  const ProbabilityChart({
    super.key,
    required this.home,
    required this.draw,
    required this.away,
  });

  final double home;
  final double draw;
  final double away;

  @override
  Widget build(BuildContext context) {
    final total = home + draw + away;
    if (total <= 0) {
      return const SizedBox(height: 180);
    }
    return SizedBox(
      height: 210,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 46,
          sections: [
            PieChartSectionData(
              value: home,
              color: AppColors.accent,
              title: '${home.toStringAsFixed(0)}%',
              radius: 54,
              titleStyle: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            PieChartSectionData(
              value: draw,
              color: AppColors.muted,
              title: '${draw.toStringAsFixed(0)}%',
              radius: 48,
              titleStyle: const TextStyle(
                color: AppColors.background,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            PieChartSectionData(
              value: away,
              color: AppColors.info,
              title: '${away.toStringAsFixed(0)}%',
              radius: 54,
              titleStyle: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
