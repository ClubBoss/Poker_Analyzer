import 'package:flutter/material.dart';
import 'info_tooltip.dart';

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
    final message = difficulty == 1
        ? 'Beginner: mostly straightforward push/fold spots.'
        : difficulty == 2
            ? 'Intermediate: mixed decisions, some multi-street play.'
            : 'Advanced: tricky, multi-way or solver-heavy spots.';
    return InfoTooltip(
      message: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _label,
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
      ),
    );
  }
}
