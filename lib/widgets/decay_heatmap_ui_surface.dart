import 'package:flutter/material.dart';

import '../services/decay_heatmap_model_generator.dart';

/// Displays decay heatmap entries as a responsive grid of colored chips.
class DecayHeatmapUISurface extends StatelessWidget {
  final List<DecayHeatmapEntry> data;
  final void Function(String tag)? onTap;

  const DecayHeatmapUISurface({super.key, required this.data, this.onTap});

  Color _colorForLevel(DecayLevel level) {
    switch (level) {
      case DecayLevel.ok:
        return Colors.green;
      case DecayLevel.warning:
        return Colors.yellow.shade700;
      case DecayLevel.critical:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Memory Risk Heatmap',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 4,
            runSpacing: -4,
            children: [
              for (final e in data)
                GestureDetector(
                  onTap: onTap != null ? () => onTap!(e.tag) : null,
                  child: Tooltip(
                    message: e.decay.toStringAsFixed(0),
                    child: Chip(
                      label: Text(
                        e.tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      backgroundColor: _colorForLevel(e.level),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
