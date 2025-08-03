import 'package:flutter/material.dart';

import '../services/pinned_learning_service.dart';
import '../services/mini_lesson_library_service.dart';
import 'pinned_learning_tile.dart';
import '../services/theory_block_library_service.dart';

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
        for (final item in items) PinnedLearningTile(item: item),
      ],
    );
  }
}
