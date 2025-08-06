import 'package:flutter/material.dart';
import '../models/v2/pack_ux_metadata.dart';

/// Horizontal filter bar for training pack library metadata.
class TrainingPackLibraryMetadataFilterBar extends StatelessWidget {
  final TrainingPackLevel? level;
  final TrainingPackTopic? topic;
  final TrainingPackFormat? format;
  final List<TrainingPackTopic> topics;
  final ValueChanged<TrainingPackLevel?> onLevelChanged;
  final ValueChanged<TrainingPackTopic?> onTopicChanged;
  final ValueChanged<TrainingPackFormat?> onFormatChanged;

  const TrainingPackLibraryMetadataFilterBar({
    super.key,
    required this.level,
    required this.topic,
    required this.format,
    required this.topics,
    required this.onLevelChanged,
    required this.onTopicChanged,
    required this.onFormatChanged,
  });

  String _label(String name) => name[0].toUpperCase() + name.substring(1);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DropdownButton<TrainingPackLevel?>(
            value: level,
            hint: const Text('Level'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final l in TrainingPackLevel.values)
                DropdownMenuItem(value: l, child: Text(_label(l.name))),
            ],
            onChanged: onLevelChanged,
          ),
          const SizedBox(width: 8),
          DropdownButton<TrainingPackTopic?>(
            value: topic,
            hint: const Text('Topic'),
            items: [
              const DropdownMenuItem(value: null, child: Text('All')),
              for (final t in topics)
                DropdownMenuItem(value: t, child: Text(_label(t.name))),
            ],
            onChanged: onTopicChanged,
          ),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [
              format == TrainingPackFormat.cash,
              format == TrainingPackFormat.tournament,
            ],
            onPressed: (index) {
              final selected =
                  index == 0 ? TrainingPackFormat.cash : TrainingPackFormat.tournament;
              final newValue = format == selected ? null : selected;
              onFormatChanged(newValue);
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Cash'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Tournament'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
