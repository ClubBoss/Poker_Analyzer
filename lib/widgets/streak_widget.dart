import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/streak_service.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<StreakService>();
    return ValueListenableBuilder<int>(
      valueListenable: service.streak,
      builder: (context, value, _) {
        if (value <= 0) return const SizedBox.shrink();
        final accent = Theme.of(context).colorScheme.secondary;
        return Row(
          children: [
            Text('🔥', style: TextStyle(color: accent)),
            const SizedBox(width: 4),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
      },
    );
  }
}
