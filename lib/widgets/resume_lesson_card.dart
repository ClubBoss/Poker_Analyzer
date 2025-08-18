import 'package:flutter/material.dart';
import '../models/player_profile.dart';
import '../models/v3/lesson_step.dart';
import '../services/lesson_resume_engine.dart';
import '../screens/lesson_step_screen.dart';
import '../screens/lesson_step_recap_screen.dart';
import 'theory_lesson_progress_widget.dart';

class ResumeLessonCard extends StatefulWidget {
  const ResumeLessonCard({super.key});

  @override
  State<ResumeLessonCard> createState() => _ResumeLessonCardState();
}

class _ResumeLessonCardState extends State<ResumeLessonCard> {
  LessonStep? _step;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final step = await const LessonResumeEngine().getResumeStep(
      PlayerProfile(),
    );
    if (mounted) setState(() => _step = step);
  }

  Future<void> _openStep() async {
    final step = _step;
    if (step == null) return;
    await Navigator.push(
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
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final step = _step;
    if (step == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Material(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _openStep,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📘 Continue lesson',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(step.title, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                const TheoryLessonProgressWidget(),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    onPressed: _openStep,
                    child: const Text('Open'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
