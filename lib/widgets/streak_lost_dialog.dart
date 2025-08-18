import 'package:flutter/material.dart';

class StreakLostDialog extends StatelessWidget {
  final int previous;
  const StreakLostDialog({super.key, required this.previous});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Стрик прерван'),
      content: Text(
        'Ты был в серии из $previous дней. Попробуем начать заново?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ок'),
        ),
      ],
    );
  }
}
