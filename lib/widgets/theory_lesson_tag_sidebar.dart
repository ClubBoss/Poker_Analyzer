import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';

/// Vertical sidebar for filtering theory lessons by tag.
class TheoryLessonTagSidebar extends StatefulWidget {
  /// Optional lesson source for testing.
  final List<TheoryMiniLessonNode>? lessons;

  /// Callback when the selected tag set changes.
  final ValueChanged<Set<String>>? onChanged;

  /// Tags selected initially.
  final Set<String> initialSelection;

  const TheoryLessonTagSidebar({
    super.key,
    this.lessons,
    this.onChanged,
    this.initialSelection = const {},
  });

  @override
  State<TheoryLessonTagSidebar> createState() => _TheoryLessonTagSidebarState();
}

class _TheoryLessonTagSidebarState extends State<TheoryLessonTagSidebar> {
  bool _loading = true;
  final Map<String, int> _counts = {};
  late List<String> _tags;
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initialSelection};
    _load();
  }

  Future<void> _load() async {
    List<TheoryMiniLessonNode> lessons = widget.lessons ?? [];
    if (lessons.isEmpty) {
      await MiniLessonLibraryService.instance.loadAll();
      lessons = MiniLessonLibraryService.instance.all;
    }
    final tags = <String>{};
    for (final l in lessons) {
      for (final t in l.tags) {
        final tag = t.trim();
        if (tag.isEmpty) continue;
        tags.add(tag);
        _counts[tag] = (_counts[tag] ?? 0) + 1;
      }
    }
    _tags = tags.toList()..sort();
    setState(() => _loading = false);
  }

  void _toggle(String tag) {
    setState(() {
      if (_selected.contains(tag)) {
        _selected.remove(tag);
      } else {
        _selected.add(tag);
      }
    });
    widget.onChanged?.call(_selected);
  }

  void _reset() {
    setState(() => _selected.clear());
    widget.onChanged?.call(_selected);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final tag in _tags)
                CheckboxListTile(
                  value: _selected.contains(tag),
                  onChanged: (_) => _toggle(tag),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: Text('$tag (${_counts[tag]})'),
                ),
            ],
          ),
        ),
        TextButton(onPressed: _reset, child: const Text('Показать всё')),
      ],
    );
  }
}
