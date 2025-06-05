import 'package:flutter/material.dart';

Future<void> showActionDialog(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Добавить действие'),
      content: const Text('Здесь будет сайзинг, тип действия и т.д.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ок')),
      ],
    ),
  );
}