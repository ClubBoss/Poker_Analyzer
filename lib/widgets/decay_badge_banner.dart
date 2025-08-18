import 'package:flutter/material.dart';

class DecayBadgeBanner extends StatelessWidget {
  final int milestone;
  final VoidCallback onClose;

  const DecayBadgeBanner({
    super.key,
    required this.milestone,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialBanner(
      backgroundColor: Colors.grey[850],
      leading: const Icon(Icons.local_fire_department, color: Colors.orange),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 \$milestone-day streak!',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No critical decay for \$milestone days',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      actions: [TextButton(onPressed: onClose, child: const Text('Close'))],
    );
  }
}
