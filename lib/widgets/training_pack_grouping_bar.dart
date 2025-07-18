import 'package:flutter/material.dart';

class TrainingPackGroupingBar extends StatefulWidget {
  final ValueChanged<String> onGroupChanged;
  final String initialGroup;

  const TrainingPackGroupingBar({
    super.key,
    required this.onGroupChanged,
    this.initialGroup = 'none',
  });

  @override
  State<TrainingPackGroupingBar> createState() =>
      _TrainingPackGroupingBarState();
}

class _TrainingPackGroupingBarState extends State<TrainingPackGroupingBar> {
  late String _group;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
  }

  void _select(String g) {
    setState(() => _group = g);
    widget.onGroupChanged(g);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('Без группировки'),
            selected: _group == 'none',
            onSelected: (_) => _select('none'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('По тегу'),
            selected: _group == 'tag',
            onSelected: (_) => _select('tag'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('По позиции'),
            selected: _group == 'position',
            onSelected: (_) => _select('position'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('По стеку'),
            selected: _group == 'stack',
            onSelected: (_) => _select('stack'),
          ),
        ],
      ),
    );
  }
}
