import 'package:flutter/material.dart';

class StreakSavedDialog extends StatelessWidget {
  const StreakSavedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Стрик сохранён'),
      content: const Text('Пропуск дня использован. Продолжай серию!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Ок'),
        ),
      ],
    );
  }
}
