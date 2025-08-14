import 'package:flutter/material.dart';

class WeaknessBoosterOverlay extends StatelessWidget {
  final List<String> tags;
  final VoidCallback onStart;
  final VoidCallback onDismiss;
  const WeaknessBoosterOverlay({
    super.key,
    required this.tags,
    required this.onStart,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final list = tags.take(2).join(', ');
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Усилить слабую зону?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'У тебя просадка в $list - хочешь отработать сейчас?',
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Да, начать тренировку'),
              ),
              TextButton(
                onPressed: onDismiss,
                child: const Text(
                  'Позже',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showWeaknessBoosterOverlay(
  BuildContext context, {
  required List<String> tags,
  required VoidCallback onStart,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => WeaknessBoosterOverlay(
      tags: tags,
      onStart: () {
        Navigator.pop(context);
        onStart();
      },
      onDismiss: () {
        Navigator.pop(context);
      },
    ),
  );
}
