import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class QuickContinueCard extends StatelessWidget {
  const QuickContinueCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingSessionService>(
      builder: (context, service, _) {
        final session = service.session;
        final template = service.template;
        if (session == null || template == null || session.isCompleted) {
          return const SizedBox.shrink();
        }
        final focus = service.focusHandTypes.map((e) => e.label).join(', ');
        final total = template.totalWeight;
        final progress = '${session.index}/$total';
        final evPct = total == 0 ? 0.0 : template.evCovered * 100 / total;
        final icmPct = total == 0 ? 0.0 : template.icmCovered * 100 / total;
        final deltaEv = evPct - service.preEvPct;
        final deltaIcm = icmPct - service.preIcmPct;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(template.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              if (focus.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(focus,
                      style: const TextStyle(color: Colors.white70)),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Вы завершили $progress рук',
                    style: const TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'EV ${deltaEv >= 0 ? '+' : ''}${deltaEv.toStringAsFixed(2)}% · ICM ${deltaIcm >= 0 ? '+' : ''}${deltaIcm.toStringAsFixed(2)}%',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen()),
                    );
                  },
                  child: const Text('Продолжить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
