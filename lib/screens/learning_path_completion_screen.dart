import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/confetti_overlay.dart';
import '../services/learning_path_progress_service.dart';
import 'learning_path_screen.dart';

class LearningPathCompletionScreen extends StatefulWidget {
  const LearningPathCompletionScreen({super.key});

  @override
  State<LearningPathCompletionScreen> createState() =>
      _LearningPathCompletionScreenState();
}

class _Stats {
  final int stages;
  final int packs;
  final double progress;

  const _Stats({
    required this.stages,
    required this.packs,
    required this.progress,
  });
}

class _LearningPathCompletionScreenState
    extends State<LearningPathCompletionScreen> {
  late Future<_Stats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
  }

  Future<_Stats> _loadStats() async {
    final stages = await LearningPathProgressService.instance
        .getCurrentStageState();
    final int stageCount = stages.length;
    int total = 0;
    double sum = 0.0;
    for (final s in stages) {
      total += s.items.length;
      for (final i in s.items) {
        sum += i.progress;
      }
    }
    final progress = total == 0 ? 0.0 : sum / total;
    return _Stats(stages: stageCount, packs: total, progress: progress);
  }

  Future<void> _reset() async {
    await LearningPathProgressService.instance.resetAll();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LearningPathScreen()),
    );
  }

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Future<void> _leaveFeedback() async {
    const uri = Uri(scheme: 'mailto', path: 'poker.analyzer.app@gmail.com');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FutureBuilder<_Stats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Поздравляем! Вы завершили путь обучения 🎉',
                    style: TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (stats != null) ...[
                    Text('Кол-во стадий: ${stats.stages}'),
                    Text('Всего паков: ${stats.packs}'),
                    Text(
                      'Средний % прогресса: ${(stats.progress * 100).toStringAsFixed(1)}%',
                    ),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Повторить путь'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _goHome,
                    icon: const Icon(Icons.home),
                    label: const Text('Вернуться в меню'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _leaveFeedback,
                    icon: const Icon(Icons.chat),
                    label: const Text('Оставить отзыв'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
