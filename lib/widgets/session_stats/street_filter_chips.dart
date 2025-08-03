import 'package:flutter/material.dart';

import '../../helpers/poker_street_helper.dart';

/// Chips allowing the user to filter session stats by poker street.
class StreetFilterChips extends StatelessWidget {
  final Set<int> selected;
  final double scale;
  final void Function(int index, bool selected) onChanged;

  const StreetFilterChips({
    super.key,
    required this.selected,
    required this.scale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Wrap(
        spacing: 8 * scale,
        children: [
          for (int i = 0; i < kStreetNames.length; i++)
            FilterChip(
              label: Text(kStreetNames[i]),
              selected: selected.contains(i),
              onSelected: (v) => onChanged(i, v),
            ),
        ],
      ),
    );
  }
}
