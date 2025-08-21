import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/recap_booster_queue.dart';
import '../services/mini_lesson_library_service.dart';
import '../widgets/booster_theory_widget.dart';
import '../screens/mini_lesson_screen.dart';
import '../theme/app_colors.dart';

class RecapBoosterScreen extends StatefulWidget {
  const RecapBoosterScreen({super.key});

  @override
  State<RecapBoosterScreen> createState() => _RecapBoosterScreenState();
}

class _RecapBoosterScreenState extends State<RecapBoosterScreen> {
  bool _loading = true;
  final List<TheoryMiniLessonNode> _lessons = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = RecapBoosterQueue.instance.getQueue();
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
      MaterialPageRoute(
        builder: (_) => MiniLessonScreen(lesson: lesson, recapTag: 'recap'),
      ),
    );
  }

  void _done() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    RecapBoosterQueue.instance.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: const Text('Повтор ключевых ошибок')),
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
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final l in _lessons)
                      BoosterTheoryWidget(
                        lesson: l,
                        slot: BoosterSlot.recap,
                        onActionTap: () => _openLesson(l),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _done,
                        style:
                            ElevatedButton.styleFrom(backgroundColor: accent),
                        child: const Text('Готово'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
