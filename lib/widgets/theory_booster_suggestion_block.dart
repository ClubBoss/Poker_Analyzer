import 'package:flutter/material.dart';

import '../services/theory_booster_suggestion_engine.dart';
import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';

class TheoryBoosterSuggestionBlock extends StatefulWidget {
  const TheoryBoosterSuggestionBlock({super.key});

  @override
  State<TheoryBoosterSuggestionBlock> createState() =>
      _TheoryBoosterSuggestionBlockState();
}

class _TheoryBoosterSuggestionBlockState
    extends State<TheoryBoosterSuggestionBlock> {
  bool _loading = true;
  List<TheoryMiniLessonNode> _lessons = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lessons = await TheoryBoosterSuggestionEngine.instance
        .suggestBoosters(maxCount: 2);
    if (mounted) {
      setState(() {
        _lessons = lessons;
        _loading = false;
      });
    }
  }

  void _open(TheoryMiniLessonNode lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    if (_loading || _lessons.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📌 Need Review?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _lessons.length; i++) ...[
            Text(
              _lessons[i].resolvedTitle,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _open(_lessons[i]),
                style: TextButton.styleFrom(foregroundColor: accent),
                child: const Text('Open'),
              ),
            ),
            if (i != _lessons.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
