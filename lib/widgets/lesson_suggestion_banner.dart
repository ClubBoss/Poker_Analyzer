import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../services/adaptive_next_step_engine.dart';
import '../services/lesson_loader_service.dart';
import '../models/v3/lesson_step.dart';
import '../screens/lesson_step_screen.dart';
import '../screens/lesson_step_recap_screen.dart';

class LessonSuggestionBanner extends StatefulWidget {
  const LessonSuggestionBanner({super.key});

  @override
  State<LessonSuggestionBanner> createState() => _LessonSuggestionBannerState();
}

class _LessonSuggestionBannerState extends State<LessonSuggestionBanner> {
  late Future<LessonStep?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<LessonStep?> _load() async {
    final engine = context.read<AdaptiveNextStepEngine>();
    final id = await engine.suggestNextStep();
    if (id == null) return null;
    final steps = await LessonLoaderService.instance.loadAllLessons();
    return steps.firstWhereOrNull((s) => s.id == id);
  }

  void _openStep(LessonStep step) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: step,
          onStepComplete: (s) async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonStepRecapScreen(step: s)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<LessonStep?>(
      future: _future,
      builder: (context, snapshot) {
        final step = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || step == null) {
          return const SizedBox.shrink();
        }
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
              Text(
                step.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (step.introText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    step.introText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _openStep(step),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Продолжить обучение'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
