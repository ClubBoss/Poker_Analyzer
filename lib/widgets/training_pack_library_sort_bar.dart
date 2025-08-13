import 'package:flutter/material.dart';

/// Sorting options for the training pack library.
enum TrainingPackSortOption { nameAsc, complexityAsc }

/// Dropdown sort bar for the training pack library.
class TrainingPackLibrarySortBar extends StatelessWidget {
  final TrainingPackSortOption sort;
  final ValueChanged<TrainingPackSortOption> onSortChanged;

  const TrainingPackLibrarySortBar({
    super.key,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<TrainingPackSortOption>(
        value: sort,
        onChanged: (value) {
          if (value != null) onSortChanged(value);
        },
        items: const [
          DropdownMenuItem(
            value: TrainingPackSortOption.nameAsc,
            child: Text('Name (A → Z)'),
          ),
          DropdownMenuItem(
            value: TrainingPackSortOption.complexityAsc,
            child: Text('Difficulty (Easy → Hard)'),
          ),
        ],
      ),
    );
  }
}
