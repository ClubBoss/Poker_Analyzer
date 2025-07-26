import 'package:flutter/material.dart';

/// Banner shown before a theory pack to provide brief context.
class TheoryIntroBanner extends StatelessWidget {
  final String title;
  final String description;
  const TheoryIntroBanner({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F4D6}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }
}

/// Shows [TheoryIntroBanner] with a fade animation.
Future<bool?> showTheoryIntroBanner(
  BuildContext context, {
  required String title,
  required String description,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Intro',
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => Center(
      child: TheoryIntroBanner(title: title, description: description),
    ),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}
