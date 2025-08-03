import 'package:flutter/material.dart';

import '../models/theory_block_model.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/pinned_learning_service.dart';
import '../services/user_progress_service.dart';
import '../utils/snackbar_util.dart';

/// Displays the same options sheet used by [TheoryBlockCardWidget] when long
/// pressed. Allows pin/unpin and quick navigation to lessons or packs.
Future<void> showTheoryBlockContextSheet(
    BuildContext context, TheoryBlockModel block) async {
  await MiniLessonLibraryService.instance.loadAll();
  final progress = UserProgressService.instance;
  var pinned = PinnedLearningService.instance.isPinned('block', block.id);

  final lessons = <_LessonEntry>[];
  for (final id in block.nodeIds) {
    final lesson = MiniLessonLibraryService.instance.getById(id);
    if (lesson == null) continue;
    final done = await progress.isTheoryLessonCompleted(id);
    lessons.add(_LessonEntry(lesson, done));
  }

  final packs = <_PackEntry>[];
  for (final id in block.practicePackIds) {
    final tpl = await PackLibraryService.instance.getById(id);
    if (tpl == null) continue;
    final done = await progress.isPackCompleted(id);
    packs.add(_PackEntry(tpl, done));
  }

  await showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined),
              title: Text(pinned ? 'Unpin Block' : 'Pin Block'),
              onTap: () async {
                Navigator.pop(ctx);
                await PinnedLearningService.instance.toggleBlock(block);
                pinned =
                    PinnedLearningService.instance.isPinned('block', block.id);
                SnackbarUtil.showMessage(context, pinned ? 'Pinned' : 'Unpinned');
              },
            ),
            if (lessons.isNotEmpty)
              const ListTile(title: Text('Lessons')),
            for (final e in lessons)
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: Text(e.lesson.title),
                trailing: Icon(
                  e.done ? Icons.check_circle : Icons.cancel,
                  color: e.done ? Colors.green : Colors.red,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => MiniLessonScreen(lesson: e.lesson),
                    ),
                  );
                },
              ),
            if (packs.isNotEmpty) const ListTile(title: Text('Drill Packs')),
            for (final e in packs)
              ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(e.pack.name),
                trailing: Icon(
                  e.done ? Icons.check_circle : Icons.cancel,
                  color: e.done ? Colors.green : Colors.red,
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => TrainingPackScreen(pack: e.pack),
                    ),
                  );
                },
              ),
          ],
        ),
      );
    },
  );
}

class _LessonEntry {
  final TheoryMiniLessonNode lesson;
  final bool done;
  _LessonEntry(this.lesson, this.done);
}

class _PackEntry {
  final TrainingPackTemplateV2 pack;
  final bool done;
  _PackEntry(this.pack, this.done);
}

