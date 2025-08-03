import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class FilterPanel extends StatelessWidget {
  final int filterDays;
  final ValueChanged<int> onFilterChanged;

  const FilterPanel({
    super.key,
    required this.filterDays,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Show:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: filterDays,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
              DropdownMenuItem(value: 90, child: Text('90 days')),
            ],
            onChanged: (value) {
              if (value != null) {
                onFilterChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
