import 'package:flutter/material.dart';
import '../models/action_entry.dart';

class StreetActionChipRow extends StatelessWidget {
  final List<ActionEntry> actions;
  const StreetActionChipRow({super.key, required this.actions});

  Color _colorForAction(ActionEntry a) {
    switch (a.action) {
      case 'fold':
        return Colors.grey;
      case 'call':
        return Colors.blue;
      case 'bet':
        return Colors.green;
      case 'raise':
        return Colors.orange;
      case 'custom':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  String _labelForAction(ActionEntry a) {
    final action = a.action;
    switch (action) {
      case 'fold':
        return 'F';
      case 'call':
        return 'C';
      case 'bet':
        return 'B';
      case 'raise':
        return 'R';
      case 'custom':
        final label = a.customLabel;
        return label != null && label.isNotEmpty ? label[0].toUpperCase() : 'C';
      default:
        return action.isNotEmpty ? action[0].toUpperCase() : '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const Text(
        'Нет действий',
        style: TextStyle(color: Colors.white54),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _colorForAction(a),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _labelForAction(a),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
