import 'package:flutter/material.dart';

import '../models/pinned_learning_item.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_screen.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/pinned_learning_service.dart';
import '../widgets/pinned_learning_tile.dart';
import '../services/theory_block_library_service.dart';
import '../services/theory_block_launcher.dart';
import '../models/theory_block_model.dart';

class PinnedHubScreen extends StatefulWidget {
  const PinnedHubScreen({super.key});

  @override
  State<PinnedHubScreen> createState() => _PinnedHubScreenState();
}

class _PinnedHubScreenState extends State<PinnedHubScreen> {
  final _service = PinnedLearningService.instance;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_reload);
    _service.load();
    MiniLessonLibraryService.instance.loadAll();
    TheoryBlockLibraryService.instance.loadAll();
  }

  void _reload() => setState(() {});

  @override
  void dispose() {
    _service.removeListener(_reload);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lessons =
        _service.items.where((e) => e.type == 'lesson').toList(growable: false);
    final packs =
        _service.items.where((e) => e.type == 'pack').toList(growable: false);
    final blocks =
        _service.items.where((e) => e.type == 'block').toList(growable: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinned Items'),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.check : Icons.edit),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSection('📘 Lessons', lessons, 'lesson'),
          _buildSection('🎯 Drill Packs', packs, 'pack'),
          _buildSection('📚 Blocks', blocks, 'block'),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<PinnedLearningItem> items, String type) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              await _reorder(type, oldIndex, newIndex);
            },
            children: [
              for (var i = 0; i < items.length; i++)
                _buildItem(type, items[i], i),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String type, PinnedLearningItem item, int index) {
    if (type == 'lesson') {
      final lesson = MiniLessonLibraryService.instance.getById(item.id);
      if (lesson == null) return const SizedBox.shrink();
      return ListTile(
        key: ValueKey('lesson:${item.id}'),
        leading: const Text('📘', style: TextStyle(fontSize: 20)),
        title: Text(lesson.title),
        trailing: _editMode
            ? ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              )
            : null,
        onTap: () => _openLesson(lesson, item),
        onLongPress: () => showPinnedLearningMenu(
          context,
          item,
          () => _openLesson(lesson, item),
        ),
      );
    }

    if (type == 'block') {
      final block = TheoryBlockLibraryService.instance.getById(item.id);
      if (block == null) return const SizedBox.shrink();
      return ListTile(
        key: ValueKey('block:${item.id}'),
        leading: const Text('📚', style: TextStyle(fontSize: 20)),
        title: Text(block.title),
        trailing: _editMode
            ? ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              )
            : null,
        onTap: () => _openBlock(block, item),
        onLongPress: () => showPinnedLearningMenu(
          context,
          item,
          () => _openBlock(block, item),
        ),
      );
    }

    return FutureBuilder<TrainingPackTemplateV2?>(
      key: ValueKey('pack:${item.id}'),
      future: PackLibraryService.instance.getById(item.id),
      builder: (context, snapshot) {
        final tpl = snapshot.data;
        if (tpl == null) return const SizedBox.shrink();
        return ListTile(
          leading: const Text('🎯', style: TextStyle(fontSize: 20)),
          title: Text(tpl.name),
          trailing: _editMode
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                )
              : null,
          onTap: () => _openPack(tpl, item),
          onLongPress: () => showPinnedLearningMenu(
            context,
            item,
            () => _openPack(tpl, item),
          ),
        );
      },
    );
  }

  Future<void> _reorder(String type, int oldIndex, int newIndex) async {
    final indices = <int>[];
    for (var i = 0; i < _service.items.length; i++) {
      if (_service.items[i].type == type) indices.add(i);
    }
    final oldGlobal = indices[oldIndex];
    int newGlobal;
    if (newIndex >= indices.length) {
      newGlobal = indices.last + 1;
    } else if (newIndex > oldIndex) {
      newGlobal = indices[newIndex] + 1;
    } else {
      newGlobal = indices[newIndex];
    }
    await _service.reorder(oldGlobal, newGlobal);
  }

  void _openLesson(dynamic lesson, PinnedLearningItem item) {
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

  void _openPack(TrainingPackTemplateV2 tpl, PinnedLearningItem item) {
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

  void _openBlock(TheoryBlockModel block, PinnedLearningItem item) {
    const TheoryBlockLauncher().launch(context: context, block: block);
  }
}

