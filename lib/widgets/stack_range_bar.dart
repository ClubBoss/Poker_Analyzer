import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/real_time_stack_range_service.dart';

class StackRangeBar extends StatelessWidget {
  const StackRangeBar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RealTimeStackRangeService>();
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Стек ${service.stack}bb • Диапазон ${service.range.length}',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
