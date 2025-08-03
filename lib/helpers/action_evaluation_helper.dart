import 'package:flutter/material.dart';

/// Shows a dialog to evaluate an action.
/// Returns selected evaluation label or null if cancelled.
Future<String?> showActionEvaluationDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Оценить действие'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'Лучшая линия'),
          child: const Text('Лучшая линия'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'Нормальная линия'),
          child: const Text('Нормальная линия'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(ctx, 'Ошибка'),
          child: const Text('Ошибка'),
        ),
      ],
    ),
  );
}

