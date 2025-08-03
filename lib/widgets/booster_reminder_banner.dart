import 'package:flutter/material.dart';

/// Banner reminding user about a pending booster for weak spots.
class BoosterReminderBanner extends StatelessWidget {
  final VoidCallback onOpen;

  const BoosterReminderBanner({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange.shade600,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Рекомендуется бустер по слабым местам',
              style: TextStyle(color: Colors.black),
            ),
          ),
          TextButton(
            onPressed: onOpen,
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Открыть'),
          ),
        ],
      ),
    );
  }
}
