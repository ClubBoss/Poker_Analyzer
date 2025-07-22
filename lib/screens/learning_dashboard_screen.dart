import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/pack_library_loader_service.dart';
import '../services/session_log_service.dart';
import '../services/training_progress_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/learning_track_engine.dart';
import '../services/tag_mastery_service.dart';
import '../services/training_session_launcher.dart';
import '../services/recommendation_feed_engine.dart';
import 'package:collection/collection.dart';
import '../services/weakness_review_engine.dart';
import '../widgets/weakness_review_section.dart';
import '../widgets/feed_recommendation_widget.dart';
import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class LearningDashboardScreen extends StatefulWidget {
  const LearningDashboardScreen({super.key});

  @override
  State<LearningDashboardScreen> createState() => _LearningDashboardScreenState();
}

class _DashboardData {
  final TrainingProgress progress;
  final TrainingPackTemplateV2? nextPack;
  final Map<String, double> improvements;
  final List<WeaknessReviewItem> reviews;
  const _DashboardData({
    required this.progress,
    required this.nextPack,
    required this.improvements,
    required this.reviews,
  });
}

class _LearningDashboardScreenState extends State<LearningDashboardScreen> {
  late Future<_DashboardData> _future;
  List<FeedRecommendationCard> _recommendationCards = [];
  List<TrainingPackTemplateV2> _packs = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashboardData> _load() async {
    final logs = context.read<SessionLogService>();
    await logs.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    _packs = packs;

    final attempts = [
      for (final log in logs.logs)
        TrainingAttempt(
          packId: log.templateId,
          spotId: log.templateId,
          timestamp: log.completedAt,
          accuracy: (log.correctCount + log.mistakeCount) == 0
              ? 0
              : log.correctCount / (log.correctCount + log.mistakeCount),
          ev: 0,
          icm: 0,
        )
    ];
    final progress = TrainingProgressService.instance.computeOverallProgress(
      attempts: attempts,
      allPacks: packs,
    );

    final stats = <String, TrainingPackStat>{};
    for (final p in packs) {
      final s = await TrainingPackStatsService.getStats(p.id);
      if (s != null) stats[p.id] = s;
    }
    final recs = const RecommendationFeedEngine().build(
      allPacks: packs,
      attempts: attempts,
      stats: stats,
    );
    if (mounted) {
      setState(() => _recommendationCards = recs);
    }
    final track = const LearningTrackEngine().computeTrack(
      allPacks: packs,
      stats: stats,
    );

    final deltas = await context.read<TagMasteryService>().computeDelta();
    final top = deltas.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final improvements = {
      for (final e in top.take(3)) e.key: e.value,
    };

    final reviewItems = const WeaknessReviewEngine().analyze(
      attempts: attempts,
      stats: stats,
      tagDeltas: deltas,
      allPacks: packs,
    );

    return _DashboardData(
      progress: progress,
      nextPack: track.nextUpPack,
      improvements: improvements,
      reviews: reviewItems,
    );
  }

  Future<void> _startPack(TrainingPackTemplateV2 pack) async {
    await const TrainingSessionLauncher().launch(pack);
  }

  Future<void> _handlePackLaunch(String id) async {
    final tpl = _packs.firstWhereOrNull((p) => p.id == id);
    if (tpl != null) {
      await _startPack(tpl);
    }
  }

  Widget _section(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _improvements(Map<String, double> data) {
    if (data.isEmpty) {
      return _section('📈 Top Improvements', 'No recent improvements');
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📈 Top Improvements',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          for (final e in data.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '↑ ${e.key} ${(e.value * 100).toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final completion = (data.progress.completionRate * 100).toStringAsFixed(0);
        final streak = data.progress.streakDays;
        return Scaffold(
          appBar: AppBar(title: const Text('Learning Dashboard')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_recommendationCards.isNotEmpty) ...[
                FeedRecommendationWidget(
                  cards: _recommendationCards,
                  onTap: _handlePackLaunch,
                ),
                const SizedBox(height: 12),
              ],
              _section('🎯 Completion', '$completion% complete'),
              const SizedBox(height: 12),
              _improvements(data.improvements),
              const SizedBox(height: 12),
              WeaknessReviewSection(
                items: data.reviews,
                onTap: _handlePackLaunch,
              ),
              const SizedBox(height: 12),
              _section('🔥 Streak', '${streak}-day streak'),
              const SizedBox(height: 12),
              if (data.nextPack != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Up: ${data.nextPack!.name}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _startPack(data.nextPack!),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: accent),
                        child: const Text('Continue Training'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
