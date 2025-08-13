import 'package:flutter/material.dart';

class TrainingPackTagFilterBar extends StatefulWidget {
  final List<String> availableTags;
  final ValueChanged<Set<String>> onChanged;
  final Set<String>? initialSelection;

  const TrainingPackTagFilterBar({
    super.key,
    required this.availableTags,
    required this.onChanged,
    this.initialSelection,
  });

  @override
  State<TrainingPackTagFilterBar> createState() =>
      _TrainingPackTagFilterBarState();
}

class _TrainingPackTagFilterBarState extends State<TrainingPackTagFilterBar> {
  late final Set<String> _selected = {...?widget.initialSelection};

  void _toggle(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        _selected.add(tag);
      }
    });
    widget.onChanged({..._selected});
  }

  void _clear() {
    setState(() => _selected.clear());
    widget.onChanged({..._selected});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: const Text('All'),
              selected: _selected.isEmpty,
              onSelected: (_) => _clear(),
              visualDensity: VisualDensity.compact,
            ),
          ),
          for (final tag in widget.availableTags)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(tag),
                selected: _selected.contains(tag),
                onSelected: (_) => _toggle(tag),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
