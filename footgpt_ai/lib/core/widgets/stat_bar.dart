import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.label,
    required this.left,
    required this.right,
    this.leftIsWinner = true,
    this.compareBars = true,
  });

  final String label;
  final String left;
  final String right;
  final bool leftIsWinner;
  final bool compareBars;

  factory StatBar.fromNumbers({
    required String label,
    required num leftValue,
    required num rightValue,
  }) {
    return StatBar(
      label: label,
      left: _format(leftValue),
      right: _format(rightValue),
      leftIsWinner: leftValue >= rightValue,
    );
  }

  factory StatBar.nullable({
    required String label,
    required num? leftValue,
    required num? rightValue,
    String unavailable = '—',
  }) {
    final comparable = leftValue != null && rightValue != null;
    return StatBar(
      label: label,
      left: leftValue == null ? unavailable : _format(leftValue),
      right: rightValue == null ? unavailable : _format(rightValue),
      leftIsWinner: comparable ? leftValue >= rightValue : true,
      compareBars: comparable,
    );
  }

  static String _format(num value) {
    if (value is int) return '$value';
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final leftNum = double.tryParse(left) ?? 0;
    final rightNum = double.tryParse(right) ?? 0;
    final total = (leftNum + rightNum) == 0 ? 1 : leftNum + rightNum;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  left,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: leftIsWinner ? AppColors.accent : AppColors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ),
              SizedBox(
                width: 48,
                child: Text(
                  right,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: leftIsWinner ? AppColors.white : AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          if (compareBars) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    Expanded(
                      flex: (leftNum / total * 100).round().clamp(1, 99),
                      child: const ColoredBox(color: AppColors.accent),
                    ),
                    Expanded(
                      flex: (rightNum / total * 100).round().clamp(1, 99),
                      child: const ColoredBox(color: AppColors.border),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
