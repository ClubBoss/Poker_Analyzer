import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../models/training_recommendation.dart';
import '../services/adaptive_learning_flow_engine.dart';
import '../services/training_session_recommender.dart';
import '../services/track_play_recorder.dart';
import '../services/tag_mastery_service.dart';
import '../services/session_log_service.dart';
import '../services/pack_library_loader_service.dart';
import '../models/training_result.dart';
import '../models/session_log.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_track.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/training_session_launcher.dart';

class TrainingRecommenderBanner extends StatefulWidget {
  const TrainingRecommenderBanner({super.key});

  @override
  State<TrainingRecommenderBanner> createState() =>
      _TrainingRecommenderBannerState();
}

class _TrainingRecommenderBannerState extends State<TrainingRecommenderBanner> {
  TrainingRecommendation? _rec;
  AdaptiveLearningPlan? _plan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<List<TrainingResult>> _resultsFromLogs(List<SessionLog> logs) async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = {
      for (final t in PackLibraryLoaderService.instance.library) t.id: t,
    };
    return [
      for (final log in logs)
        TrainingResult(
          date: log.completedAt,
          total: log.correctCount + log.mistakeCount,
          correct: log.correctCount,
          accuracy: (log.correctCount + log.mistakeCount) == 0
              ? 0
              : log.correctCount * 100 / (log.correctCount + log.mistakeCount),
          tags: library[log.templateId]?.tags ?? log.categories.keys.toList(),
        ),
    ];
  }

  Future<void> _load() async {
    final logs = context.read<SessionLogService>();
    final results = await _resultsFromLogs(logs.logs);
    final mastery = await context.read<TagMasteryService>().computeMastery();
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    const engine = AdaptiveLearningFlowEngine();
    final plan = engine.generate(
      history: results,
      tagMastery: mastery,
      sourcePacks: packs,
    );
    final history = await TrackPlayRecorder.instance.getHistory();
    final recs = const TrainingSessionRecommender().recommend(
      plan: plan,
      history: history,
    );
    if (mounted) {
      setState(() {
        _rec = recs.firstOrNull;
        _plan = plan;
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final rec = _rec;
    final plan = _plan;
    if (rec == null || plan == null) return;
    TrainingPackTemplateV2? pack;
    String goalId = rec.goalTag ?? '';
    if (rec.type == TrainingRecommendationType.mistakeReplay) {
      pack = plan.mistakeReplayPack;
      goalId = 'mistake_replay';
    } else {
      final track = plan.recommendedTracks.firstWhereOrNull(
        (t) => t.id == rec.packId,
      );
      if (track != null) {
        pack = TrainingPackTemplateV2(
          id: track.id,
          name: track.title,
          trainingType: TrainingType.pushFold,
          tags: List<String>.from(track.tags),
          spots: track.spots,
          spotCount: track.spots.length,
          created: DateTime.now(),
          gameType: GameType.tournament,
          positions: const [],
          meta: const {'origin': 'learning_track'},
        );
      }
    }
    if (pack == null) return;
    await TrackPlayRecorder.instance.recordStart(goalId);
    await const TrainingSessionLauncher().launch(pack);
  }

  @override
  Widget build(BuildContext context) {
    final rec = _rec;
    if (_loading || rec == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final step = (rec.progress * 3).round().clamp(0, 2) + 1;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6A5AE0), Color(0xFF8E7BFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rec.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            rec.reason == 'mistake_replay'
                ? 'Mistake replay · urgent'
                : 'Weakness drill',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Step $step of 3',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _start,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Продолжить'),
            ),
          ),
        ],
      ),
    );
  }
}
