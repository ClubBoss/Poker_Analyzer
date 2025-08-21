import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/inbox_booster_tracker_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../widgets/booster_theory_widget.dart';
import '../screens/mini_lesson_screen.dart';
import '../theme/app_colors.dart';

class InboxBoosterScreen extends StatefulWidget {
  const InboxBoosterScreen({super.key});

  @override
  State<InboxBoosterScreen> createState() => _InboxBoosterScreenState();
}

class _InboxBoosterScreenState extends State<InboxBoosterScreen> {
  bool _loading = true;
  final List<TheoryMiniLessonNode> _lessons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await InboxBoosterTrackerService.instance.getInbox();
    await MiniLessonLibraryService.instance.loadAll();
    final list = [
      for (final id in ids) MiniLessonLibraryService.instance.getById(id),
    ].whereType<TheoryMiniLessonNode>().toList();
    if (!mounted) return;
    setState(() {
      _lessons
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  Future<void> _openLesson(TheoryMiniLessonNode lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
    await InboxBoosterTrackerService.instance.markClicked(lesson.id);
    await InboxBoosterTrackerService.instance.removeFromInbox(lesson.id);
    if (mounted) {
      await _load();
    }
  }

  Future<void> _clear() async {
    await InboxBoosterTrackerService.instance.clearInbox();
    if (mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: const Text('Теория по теме')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _lessons.isEmpty
              ? const Center(
                  child: Text(
                    'Нет бустеров',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final l in _lessons)
                        BoosterTheoryWidget(
                          lesson: l,
                          slot: BoosterSlot.inbox,
                          onActionTap: () => _openLesson(l),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _clear,
                          style:
                              ElevatedButton.styleFrom(backgroundColor: accent),
                          child: const Text('Очистить'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
