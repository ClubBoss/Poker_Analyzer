import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/v3/lesson_step.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/training_session_service.dart';
import '../services/lesson_progress_service.dart';
import 'training_session_screen.dart';

class LessonStepScreen extends StatefulWidget {
  final LessonStep step;
  const LessonStepScreen({super.key, required this.step});

  @override
  State<LessonStepScreen> createState() => _LessonStepScreenState();
}

class _LessonStepScreenState extends State<LessonStepScreen> {
  int? _selectedOption;
  bool _trainingCompleted = false;

  Future<void> _startTraining() async {
    final tpl = await context
        .read<TrainingPackTemplateStorageService>()
        .loadBuiltinTemplate(widget.step.linkedPackId);
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
    if (mounted) setState(() => _trainingCompleted = true);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    final children = <Widget>[
      Text(
        step.introText,
        style: const TextStyle(color: Colors.white),
      ),
    ];

    final img = step.rangeImageUrl;
    if (img != null && img.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: img.startsWith('http')
              ? Image.network(img)
              : Image.asset(img),
        ),
      );
    }

    final quiz = step.quiz;
    if (quiz != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            quiz.question,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
      for (var i = 0; i < quiz.options.length; i++) {
        children.add(
          RadioListTile<int>(
            activeColor: Colors.orange,
            title: Text(
              quiz.options[i],
              style: const TextStyle(color: Colors.white),
            ),
            value: i,
            groupValue: _selectedOption,
            onChanged: (v) => setState(() => _selectedOption = v),
          ),
        );
      }
    }

    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: !_trainingCompleted
            ? ElevatedButton(
                onPressed: _startTraining,
                child: const Text('Начать тренировку'),
              )
            : ElevatedButton(
                onPressed: () async {
                  await LessonProgressService.instance
                      .markCompleted(step.id);
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Завершить шаг'),
              ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(step.title)),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
