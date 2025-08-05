import 'package:flutter/material.dart';

import '../services/effective_theory_injector_service.dart';
import '../models/theory_lesson_node.dart';
import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';

/// Displays up to two theory booster lessons for a given tag inside the
/// training flow.
///
/// Lessons are loaded via [EffectiveTheoryInjectorService]. When no lessons are
/// available an empty widget is rendered.
class InlineTheoryBoosterDisplay extends StatefulWidget {
  final String tag;
  final EffectiveTheoryInjectorService injector;

  const InlineTheoryBoosterDisplay({
    super.key,
    required this.tag,
    EffectiveTheoryInjectorService? injector,
  }) : injector = injector ?? EffectiveTheoryInjectorService();

  @override
  State<InlineTheoryBoosterDisplay> createState() =>
      _InlineTheoryBoosterDisplayState();
}

class _InlineTheoryBoosterDisplayState
    extends State<InlineTheoryBoosterDisplay> {
  late Future<List<TheoryLessonNode>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.injector.getInjectableLessonsForTag(widget.tag);
  }

  @override
  void didUpdateWidget(covariant InlineTheoryBoosterDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tag != widget.tag) {
      _future = widget.injector.getInjectableLessonsForTag(widget.tag);
    }
  }

  void _openLesson(TheoryLessonNode lesson) {
    final mini = TheoryMiniLessonNode(
      id: lesson.id,
      refId: lesson.refId,
      title: lesson.title,
      content: lesson.content,
      nextIds: lesson.nextIds,
      recoveredFromMistake: lesson.recoveredFromMistake,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: mini)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TheoryLessonNode>>(
      future: _future,
      builder: (context, snapshot) {
        final lessons = snapshot.data;
        if (lessons == null || lessons.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ExpansionTile(
            title: const Text('📘 Theory Boosters'),
            children: [
              for (final l in lessons)
                ListTile(
                  title: Text(l.resolvedTitle),
                  trailing: TextButton(
                    onPressed: () => _openLesson(l),
                    child: const Text('Open'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

