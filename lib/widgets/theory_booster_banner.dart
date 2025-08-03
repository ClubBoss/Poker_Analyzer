import 'package:flutter/material.dart';

/// Banner prompting user to complete missed theory block.
class TheoryBoosterBanner extends StatelessWidget {
  final VoidCallback onOpen;

  const TheoryBoosterBanner({super.key, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Вы пропустили теоретический блок',
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
