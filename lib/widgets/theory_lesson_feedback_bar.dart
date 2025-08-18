import 'package:flutter/material.dart';

import '../models/theory_lesson_feedback.dart';
import '../services/theory_feedback_storage.dart';

class TheoryLessonFeedbackBar extends StatefulWidget {
  final String lessonId;

  const TheoryLessonFeedbackBar({super.key, required this.lessonId});

  @override
  State<TheoryLessonFeedbackBar> createState() =>
      _TheoryLessonFeedbackBarState();
}

class _TheoryLessonFeedbackBarState extends State<TheoryLessonFeedbackBar> {
  TheoryLessonFeedbackChoice? _choice;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fb = await TheoryFeedbackStorage.instance.getFeedback(
      widget.lessonId,
    );
    if (mounted) setState(() => _choice = fb?.choice);
  }

  Future<void> _select(TheoryLessonFeedbackChoice choice) async {
    await TheoryFeedbackStorage.instance.record(widget.lessonId, choice);
    if (mounted) {
      setState(() => _choice = choice);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Спасибо за отзыв!')));
    }
  }

  Widget _button(
    TheoryLessonFeedbackChoice choice,
    String label,
    IconData icon,
  ) {
    final accent = Theme.of(context).colorScheme.secondary;
    final selected = _choice == choice;
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _select(choice),
        icon: Icon(icon, color: accent),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? Colors.white : accent,
          side: BorderSide(color: accent),
          backgroundColor: selected ? accent.withValues(alpha: 0.2) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Оцените урок:', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              _button(
                TheoryLessonFeedbackChoice.useful,
                'Полезно',
                Icons.thumb_up_alt_outlined,
              ),
              const SizedBox(width: 8),
              _button(
                TheoryLessonFeedbackChoice.unclear,
                'Непонятно',
                Icons.help_outline,
              ),
              const SizedBox(width: 8),
              _button(
                TheoryLessonFeedbackChoice.hard,
                'Сложно',
                Icons.whatshot_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
