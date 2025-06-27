import 'package:flutter/material.dart';
import '../helpers/color_utils.dart';

Future<String?> showColorTagDialog(BuildContext context) {
  const colors = [
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.grey,
    Colors.teal,
    Colors.pink,
  ];
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Color Tag'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in colors)
            GestureDetector(
              onTap: () => Navigator.pop(context, colorToHex(c)),
              child: CircleAvatar(backgroundColor: c),
            ),
        ],
      ),
    ),
  );
}
