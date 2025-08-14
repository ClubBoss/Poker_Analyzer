import 'package:flutter/material.dart';

import '../models/line_graph_node.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import '../screens/mini_lesson_screen.dart';
import '../services/line_graph_engine.dart';
import '../services/pack_library_service.dart';
import '../services/training_session_launcher.dart';

/// Displays lessons and training packs linked to a [LineGraphNode].
class LineGraphNodeDetailWidget extends StatelessWidget {
  final LineGraphNode node;
  final LineGraphEngine engine;

  const LineGraphNodeDetailWidget({
    super.key,
    required this.node,
    required this.engine,
  });

  String _title(LineGraphNode n) {
    String cap(String v) => v.isEmpty ? v : v[0].toUpperCase() + v.substring(1);
    return '${cap(n.street)} ${cap(n.action)} - ${n.position}';
  }

  Future<void> _openLesson(
    BuildContext context,
    TheoryMiniLessonNode lesson,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  Future<void> _startPack(BuildContext context, TrainingPackSpot spot) async {
    final packId = spot.meta['packId']?.toString();
    if (packId == null) return;
    final tpl = await PackLibraryService.instance.getById(packId);
    if (tpl == null) return;
    await const TrainingSessionLauncher().launch(tpl);
  }

  @override
  Widget build(BuildContext context) {
    final lessons = engine.findLinkedLessons(node);
    final packs = engine.findLinkedPacks(node);
    final title = _title(node);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (lessons.isEmpty && packs.isEmpty) ...[
          const Text('Нет связанных уроков или тренировок'),
        ] else ...[
          if (lessons.isNotEmpty) ...[
            for (final l in lessons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(l.resolvedTitle)),
                    ElevatedButton(
                      onPressed: () => _openLesson(context, l),
                      child: const Text('Открыть'),
                    ),
                  ],
                ),
              ),
            if (packs.isNotEmpty) const SizedBox(height: 16),
          ],
          if (packs.isNotEmpty) ...[
            for (final p in packs)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: Text(p.title)),
                    ElevatedButton(
                      onPressed: () => _startPack(context, p),
                      child: const Text('Начать'),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ],
    );
  }
}
