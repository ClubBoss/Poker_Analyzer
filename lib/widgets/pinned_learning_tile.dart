import 'package:flutter/material.dart';

import '../models/pinned_learning_item.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/pinned_learning_service.dart';
import '../services/theory_block_library_service.dart';
import '../services/theory_block_launcher.dart';
import '../models/theory_block_model.dart';

class PinnedLearningTile extends StatelessWidget {
  const PinnedLearningTile({super.key, required this.item});

  final PinnedLearningItem item;

  @override
  Widget build(BuildContext context) {
    if (item.type == 'lesson') {
      final lesson = MiniLessonLibraryService.instance.getById(item.id);
      if (lesson == null) return const SizedBox.shrink();
      return ListTile(
        leading: const Text('📘', style: TextStyle(fontSize: 20)),
        title: Text(lesson.title),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => PinnedLearningService.instance.unpin('lesson', item.id),
        ),
        onTap: () => _openLesson(context, lesson),
        onLongPress: () => showPinnedLearningMenu(
          context,
          item,
          () => _openLesson(context, lesson),
        ),
      );
    }

    if (item.type == 'block') {
      return FutureBuilder<void>(
        future: TheoryBlockLibraryService.instance.loadAll(),
        builder: (context, snapshot) {
          final block = TheoryBlockLibraryService.instance.getById(item.id);
          if (block == null) return const SizedBox.shrink();
          return ListTile(
            leading: const Text('📚', style: TextStyle(fontSize: 20)),
            title: Text(block.title),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  PinnedLearningService.instance.unpin('block', item.id),
            ),
            onTap: () => _openBlock(context, block),
            onLongPress: () => showPinnedLearningMenu(
              context,
              item,
              () => _openBlock(context, block),
            ),
          );
        },
      );
    }

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
            onPressed: () => PinnedLearningService.instance.unpin('pack', item.id),
          ),
          onTap: () => _openPack(context, tpl),
          onLongPress: () => showPinnedLearningMenu(
            context,
            item,
            () => _openPack(context, tpl),
          ),
        );
      },
    );
  }

  void _openLesson(BuildContext context, dynamic lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MiniLessonScreen(
          lesson: lesson,
          initialPosition: item.lastPosition,
        ),
      ),
    );
  }

  void _openPack(BuildContext context, TrainingPackTemplateV2 tpl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackScreen(
          pack: tpl,
          initialPosition: item.lastPosition,
        ),
      ),
    );
  }

  void _openBlock(BuildContext context, TheoryBlockModel block) {
    const TheoryBlockLauncher().launch(context: context, block: block);
  }

}

Future<void> showPinnedLearningMenu(
  BuildContext context,
  PinnedLearningItem item,
  VoidCallback open,
) async {
  final service = PinnedLearningService.instance;
  final hasMultiple = service.items.length > 1;
  final result = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () => Navigator.pop(context, 'open'),
          ),
          ListTile(
            leading: const Icon(Icons.push_pin_outlined),
            title: const Text('Unpin'),
            onTap: () => Navigator.pop(context, 'unpin'),
          ),
          if (hasMultiple)
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: const Text('Move to Top'),
              onTap: () => Navigator.pop(context, 'top'),
            ),
        ],
      ),
    ),
  );

  switch (result) {
    case 'open':
      open();
      break;
    case 'unpin':
      await service.unpin(item.type, item.id);
      break;
    case 'top':
      await service.moveToTop(item.type, item.id);
      break;
  }
}


