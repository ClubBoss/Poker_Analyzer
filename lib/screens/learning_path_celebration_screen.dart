import 'package:flutter/material.dart';

import '../models/learning_path_template_v2.dart';
import '../widgets/confetti_overlay.dart';
import '../services/path_suggestion_service.dart';
import 'learning_path_screen.dart';
import 'skill_map_screen.dart';

class LearningPathCelebrationScreen extends StatefulWidget {
  final LearningPathTemplateV2 path;
  const LearningPathCelebrationScreen({super.key, required this.path});

  @override
  State<LearningPathCelebrationScreen> createState() =>
      _LearningPathCelebrationScreenState();
}

class _LearningPathCelebrationScreenState
    extends State<LearningPathCelebrationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
  }

  void _repeat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LearningPathScreen()),
    );
  }

  Future<void> _nextPath() async {
    final next = await PathSuggestionService.instance.nextPath();
    if (!mounted) return;
    if (next == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Next path coming soon')),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathCelebrationScreen(path: next),
      ),
    );
  }

  void _skills() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SkillMapScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Поздравляем!',
                style: TextStyle(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Вы завершили путь "${widget.path.title}"',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _repeat,
                icon: const Text('🔁'),
                label: const Text('Повторить'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _nextPath,
                icon: const Text('➡️'),
                label: const Text('Следующий путь'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _skills,
                icon: const Icon(Icons.bar_chart),
                label: const Text('Мои навыки'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
