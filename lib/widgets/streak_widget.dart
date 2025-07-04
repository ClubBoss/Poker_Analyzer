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
      builder: (_, value, __) {
        if (value <= 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}
