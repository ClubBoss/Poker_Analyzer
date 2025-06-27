import 'package:flutter/material.dart';

class DifficultyChip extends StatelessWidget {
  final int difficulty;
  const DifficultyChip(this.difficulty, {super.key});

  Color get _color {
    switch (difficulty) {
      case 2:
        return Colors.amber.shade400;
      case 3:
        return Colors.red.shade400;
      default:
        return Colors.green.shade400;
    }
  }

  String get _label {
    switch (difficulty) {
      case 2:
        return 'Interm.';
      case 3:
        return 'Adv.';
      default:
        return 'Beginner';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
    );
  }
}
