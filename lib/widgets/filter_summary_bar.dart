import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FilterSummaryBar extends StatelessWidget {
  final String summary;
  final VoidCallback onReset;
  final VoidCallback onChange;
  const FilterSummaryBar(
      {super.key,
      required this.summary,
      required this.onReset,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cardBackground,
      child: Row(
        children: [
          Expanded(
            child: Text(summary, style: const TextStyle(color: Colors.white)),
          ),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, color: Colors.grey),
            label: const Text('Сбросить всё',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onChange,
            icon: const Icon(Icons.tune, color: Colors.grey),
            label:
                const Text('Изменить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
