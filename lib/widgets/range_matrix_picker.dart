import 'package:flutter/material.dart';

class RangeMatrixPicker extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const RangeMatrixPicker({super.key, required this.selected, required this.onChanged});

  static const _ranks = [
    'A',
    'K',
    'Q',
    'J',
    'T',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2'
  ];

  String _label(int row, int col) {
    final r1 = _ranks[row];
    final r2 = _ranks[col];
    if (row == col) return '$r1$r2';
    if (row < col) return '${r1}${r2}s';
    return '${r2}${r1}o';
  }

  Color _baseColor(int row, int col) {
    if (row == col) return Colors.orange;
    if (row < col) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int row = 0; row < 13; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int col = 0; col < 13; col++)
                _Cell(
                  label: _label(row, col),
                  color: _baseColor(row, col),
                  selected: selected.contains(_label(row, col)),
                  onTap: () {
                    final newSet = Set<String>.from(selected);
                    final hand = _label(row, col);
                    if (!newSet.add(hand)) newSet.remove(hand);
                    onChanged(newSet);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _Cell({required this.label, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color : color.withOpacity(0.4);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onTap,
      child: Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.all(1),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
