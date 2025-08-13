import 'package:flutter/material.dart';
import 'badge_icon.dart';

class BadgeCelebrationDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  const BadgeCelebrationDialog(
      {super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black87,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BadgeIcon(icon, size: 64),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

Future<void> showBadgeCelebrationDialog(
    BuildContext context, IconData icon, String title) {
  return showDialog(
    context: context,
    builder: (_) => BadgeCelebrationDialog(icon: icon, title: title),
  );
}
