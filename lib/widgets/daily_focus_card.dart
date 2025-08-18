import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/daily_focus_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class DailyFocusCard extends StatelessWidget {
  const DailyFocusCard({super.key});

  String _capitalize(String s) =>
      s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : s;

  Future<void> _start(BuildContext context) async {
    final tpl = await context.read<DailyFocusService>().buildPack();
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyFocusService>();
    final tag = service.tag;
    final accent = Theme.of(context).colorScheme.secondary;
    const title = '🎯 Сегодняшний фокус';
    final desc = tag == null
        ? 'Тренируйте 10 раздач для возобновления серии'
        : '${_capitalize(tag)}: низкий винрейт';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            title,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: () => _start(context),
              child: const Text('Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
