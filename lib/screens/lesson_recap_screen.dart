import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

import '../models/v3/lesson_step.dart';
import '../services/adaptive_next_step_engine.dart';
import '../services/lesson_loader_service.dart';
import 'lesson_step_screen.dart';
import 'track_progress_dashboard_screen.dart';

class LessonRecapScreen extends StatefulWidget {
  final LessonStep step;
  const LessonRecapScreen({super.key, required this.step});

  @override
  State<LessonRecapScreen> createState() => _LessonRecapScreenState();
}

class _LessonRecapScreenState extends State<LessonRecapScreen>
    with SingleTickerProviderStateMixin {
  late Future<LessonStep?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<LessonStep?> _load() async {
    final engine = context.read<AdaptiveNextStepEngine>();
    final nextId = await engine.suggestNextStep();
    if (nextId == null || nextId == widget.step.id) return null;
    final steps = await LessonLoaderService.instance.loadAllLessons();
    return steps.firstWhereOrNull((s) => s.id == nextId);
  }

  void _openNext(LessonStep? next) {
    if (next == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TrackProgressDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LessonStepScreen(
            step: next,
            onStepComplete: (s) async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LessonRecapScreen(step: s)),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: const Text('Резюме шага')),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<LessonStep?>(
        future: _future,
        builder: (context, snapshot) {
          final next = snapshot.data;
          final done = snapshot.connectionState == ConnectionState.done;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: done ? 1 : 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.step.title} \u2014 \u2713 Завершено',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.step.summaryText.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.step.summaryText,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const Spacer(),
                  if (done)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (next != null)
                          Text(
                            'Следующий шаг: ${next.title}',
                            style: const TextStyle(color: Colors.white),
                          )
                        else
                          const Text(
                            'Вы прошли все рекомендованные шаги.',
                            style: TextStyle(color: Colors.white),
                          ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _openNext(next),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: accent),
                            child: const Text('Далее \u2192'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
