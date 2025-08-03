import 'package:flutter/material.dart';

/// Panel with search field and basic dropdown filters used by
/// [TrainingSpotList]. The widget is intentionally lightweight and keeps
/// all state in the parent so it can be easily reused by different list
/// implementations.
class TrainingSpotFilterPanel extends StatelessWidget {
  /// Controller for the search text field.
  final TextEditingController searchController;

  /// Called whenever the search query changes.
  final ValueChanged<String> onSearchChanged;

  /// Available tag values for filtering.
  final Set<String> tags;

  /// Available positions for filtering.
  final Set<String> positions;

  /// Currently selected position filter. `"All"` means no filtering.
  final String positionValue;

  /// Currently selected tag filter. `"All"` means no filtering.
  final String tagValue;

  final ValueChanged<String?> onPositionChanged;
  final ValueChanged<String?> onTagChanged;

  const TrainingSpotFilterPanel({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.tags,
    required this.positions,
    required this.positionValue,
    required this.tagValue,
    required this.onPositionChanged,
    required this.onTagChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Поиск',
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          // Position filter
          DropdownButton<String>(
            value: positionValue,
            underline: const SizedBox.shrink(),
            onChanged: onPositionChanged,
            items: ['All', ...positions]
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
          ),
          const SizedBox(width: 12),
          // Tag filter
          DropdownButton<String>(
            value: tagValue,
            underline: const SizedBox.shrink(),
            onChanged: onTagChanged,
            items: ['All', ...tags]
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

