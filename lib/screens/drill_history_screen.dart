import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/goals_service.dart';
import '../theme/app_colors.dart';

class DrillHistoryScreen extends StatelessWidget {
  const DrillHistoryScreen({super.key});

  String _fmt(DateTime d) => DateFormat('d MMMM yyyy', 'ru').format(d);

  @override
  Widget build(BuildContext context) {
    final results = [...context.watch<GoalsService>().drillResults]
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                'История пока пуста',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final r = results[index];
                final icon = r.type == 'mistake' ? '❗️' : '🏁';
                final type = r.type == 'mistake' ? 'Ошибки' : 'Цель';
                final status = (r.completed ?? true) ? 'Завершено' : 'Прервано';
                final count = '${r.handsSeen ?? r.total} / ${r.total}';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Text(icon, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      _fmt(r.date),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Тип тренировки: $type',
                            style: const TextStyle(color: Colors.white70)),
                        Text('Кол-во рук: $count',
                            style: const TextStyle(color: Colors.white70)),
                        Text('Статус: $status',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

