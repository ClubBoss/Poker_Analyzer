import 'package:flutter/material.dart';

import '../services/pinned_learning_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';
import '../models/pinned_learning_item.dart';
import '../models/v2/training_pack_template_v2.dart';

class PinnedLearningSection extends StatefulWidget {
  const PinnedLearningSection({super.key});

  @override
  State<PinnedLearningSection> createState() => _PinnedLearningSectionState();
}

class _PinnedLearningSectionState extends State<PinnedLearningSection> {
  final _service = PinnedLearningService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_reload);
    _service.load();
    MiniLessonLibraryService.instance.loadAll();
  }

  void _reload() => setState(() {});

  @override
  void dispose() {
    _service.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _service.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Pinned Items',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        for (final item in items) _buildTile(item),
      ],
    );
  }

  Widget _buildTile(PinnedLearningItem item) {
    if (item.type == 'lesson') {
      final lesson = MiniLessonLibraryService.instance.getById(item.id);
      if (lesson == null) return const SizedBox.shrink();
      return ListTile(
        leading: const Text('📘', style: TextStyle(fontSize: 20)),
        title: Text(lesson.title),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _service.unpin('lesson', item.id),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
          );
        },
      );
    } else {
      return FutureBuilder<TrainingPackTemplateV2?>(
        future: PackLibraryService.instance.getById(item.id),
        builder: (context, snapshot) {
          final tpl = snapshot.data;
          if (tpl == null) return const SizedBox.shrink();
          return ListTile(
            leading: const Text('🎯', style: TextStyle(fontSize: 20)),
            title: Text(tpl.name),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _service.unpin('pack', item.id),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: tpl)),
              );
            },
          );
        },
      );
    }
  }
}
