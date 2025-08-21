import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/learning_path_completion_service.dart';
import '../services/learning_track_engine.dart';
import '../services/lesson_track_meta_service.dart';
import '../widgets/streak_badge_widget.dart';
import '../widgets/daily_challenge_streak_banner_widget.dart';
import '../widgets/reward_banner_widget.dart';
import 'daily_challenge_history_screen.dart';
import 'master_achievements_screen.dart';
import 'player_stats_screen.dart';
import 'mistake_review_screen.dart';
import 'mistake_insight_screen.dart';

class MasterModeScreen extends StatefulWidget {
  static const route = '/master_mode';
  const MasterModeScreen({super.key});

  @override
  State<MasterModeScreen> createState() => _MasterModeScreenState();
}

class _MasterModeScreenState extends State<MasterModeScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final date =
        await LearningPathCompletionService.instance.getCompletionDate();
    final tracks = const LearningTrackEngine().getTracks();
    var completedTracks = 0;
    for (final t in tracks) {
      final meta = await LessonTrackMetaService.instance.load(t.id);
      if (meta?.completedAt != null) {
        completedTracks += 1;
      }
    }
    return {
      'date': date,
      'completedTracks': completedTracks,
      'totalTracks': tracks.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔥 Мастер-режим'), centerTitle: true),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final date = data?['date'] as DateTime?;
          final completed = data?['completedTracks'] as int? ?? 0;
          final total = data?['totalTracks'] as int? ?? 0;

          final stats = 'Завершено треков: $completed / $total';
          final dateText = date != null
              ? 'Путь завершён: ${DateFormat('dd.MM.yyyy').format(date)}'
              : 'Путь завершён';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const DailyChallengeStreakBannerWidget(),
              const StreakBadgeWidget(),
              const RewardBannerWidget(),
              Text(dateText, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(stats, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {},
                child: const Text('🎯 Начать челлендж'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyChallengeHistoryScreen(),
                    ),
                  );
                },
                child: const Text('📅 История'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  );
                },
                child: const Text('🎖 Достижения'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('🔁 Повторить трек'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MistakeReviewScreen(),
                    ),
                  );
                },
                child: const Text('🔁 Повтор ошибок'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MistakeInsightScreen(),
                    ),
                  );
                },
                child: const Text('📊 Аналитика ошибок'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: const Text('📈 Анализ прогресса'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlayerStatsScreen(),
                    ),
                  );
                },
                child: const Text('📈 Моя статистика'),
              ),
            ],
          );
        },
      ),
    );
  }
}
