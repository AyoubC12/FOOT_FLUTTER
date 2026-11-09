import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../tactics/formation_templates.dart';

class FormationSelector extends StatelessWidget {
  const FormationSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final formation in FormationTemplates.names)
          ChoiceChip(
            label: Text(formation),
            selected: value == formation,
            selectedColor: AppColors.accentMuted,
            labelStyle: TextStyle(
              color: value == formation ? AppColors.accent : AppColors.white,
            ),
            onSelected: (_) => onChanged(formation),
          ),
      ],
    );
  }
}
