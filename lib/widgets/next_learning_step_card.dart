import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auto_advance_pack_engine.dart';
import '../services/training_session_service.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/training_session_screen.dart';

class NextLearningStepCard extends StatefulWidget {
  const NextLearningStepCard({super.key});

  @override
  State<NextLearningStepCard> createState() => _NextLearningStepCardState();
}

class _NextLearningStepCardState extends State<NextLearningStepCard> {
  late Future<TrainingPackTemplateV2?> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _future = AutoAdvancePackEngine.instance.getNextRecommendedPack();
  }

  Future<void> _start(TrainingPackTemplateV2 tpl) async {
    if (_starting) return;
    setState(() => _starting = true);
    final template = TrainingPackTemplate.fromJson(tpl.toJson());
    await context.read<TrainingSessionService>().startSession(template);
    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
    if (mounted) setState(() => _starting = false);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<TrainingPackTemplateV2?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final tpl = snapshot.data;
        if (tpl == null) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 Продолжить обучение',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(tpl.name, style: const TextStyle(color: Colors.white)),
              if (tpl.description.isNotEmpty)
                Text(
                  tpl.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _starting ? null : () => _start(tpl),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Начать'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
