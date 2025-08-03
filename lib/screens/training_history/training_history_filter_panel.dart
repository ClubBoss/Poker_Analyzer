import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import 'training_history_view_model.dart';

class TrainingHistoryFilterPanel extends StatelessWidget {
  const TrainingHistoryFilterPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrainingHistoryViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('Show:', style: TextStyle(color: Colors.white)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: vm.filterDays,
            dropdownColor: AppColors.cardBackground,
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 7, child: Text('7 days')),
              DropdownMenuItem(value: 30, child: Text('30 days')),
              DropdownMenuItem(value: 90, child: Text('90 days')),
            ],
            onChanged: (value) {
              if (value != null) {
                vm.setFilterDays(value);
              }
            },
          ),
          const Spacer(),
          Text(
            'Average Accuracy: ${vm.averageAccuracy().toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

