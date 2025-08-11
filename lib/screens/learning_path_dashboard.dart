import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../models/learning_track_progress_model.dart';
import '../services/learning_path_gatekeeper_service.dart';
import '../services/learning_track_progress_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/session_log_service.dart';
import '../services/training_path_progress_service_v2.dart';
import '../services/streak_progress_service.dart';
import '../services/learning_path_stage_launcher.dart';
import '../widgets/learning_path_stage_tile.dart';
import 'learning_path_stage_list_screen.dart';
import '../services/overlay_decay_booster_orchestrator.dart';
import 'dart:async';

/// Dashboard summarizing progress in a learning path and suggesting
/// the next stage to continue.
class LearningPathDashboard extends StatefulWidget {
  final Future<LearningPathTemplateV2> pathFuture;
  const LearningPathDashboard({super.key, required this.pathFuture});

  @override
  State<LearningPathDashboard> createState() => _LearningPathDashboardState();
}

class _LearningPathDashboardState extends State<LearningPathDashboard> {
  late SessionLogService _logs;
  late TrainingPathProgressServiceV2 _progress;
  late LearningPathGatekeeperService _gatekeeper;
  late LearningTrackProgressService _service;
  LearningTrackProgressModel? _model;
  LearningPathTemplateV2? _path;
  StreakData? _streak;
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _logs = context.read<SessionLogService>();
      _progress = TrainingPathProgressServiceV2(logs: _logs);
      _gatekeeper = LearningPathGatekeeperService(
        progress: _progress,
        mastery: context.read<TagMasteryService>(),
      );
      _service = LearningTrackProgressService(
        progress: _progress,
        gatekeeper: _gatekeeper,
      );
      widget.pathFuture.then((p) {
        if (!mounted) return;
        _path = p;
        _load();
      });
      _initialized = true;
    }
  }

  Future<void> _load() async {
    final path = _path;
    if (path == null) return;
    setState(() => _loading = true);
    await _logs.load();
    final model = await _service.build(path.id);
    final streak = await StreakProgressService.instance.getStreak();
    if (!mounted) return;
    setState(() {
      _model = model;
      _streak = streak;
      _loading = false;
    });
    unawaited(
        OverlayDecayBoosterOrchestrator.instance.maybeShow(context));
  }

  Future<void> _continueTraining() async {
    final next = _nextStage();
    if (next == null) return;
    await const LearningPathStageLauncher().launch(context, next);
    if (mounted) _load();
  }

  LearningPathStageModel? _nextStage() {
    final statuses = _model?.stages ?? const <StageProgressStatus>[];
    final nextId = statuses
        .firstWhereOrNull((s) => s.status == StageStatus.unlocked)
        ?.stageId;
    if (nextId == null) return null;
    return _path?.stages.firstWhereOrNull((s) => s.id == nextId);
  }

  List<LearningPathStageModel> _previewStages() {
    final statuses = _model?.stages ?? const <StageProgressStatus>[];
    final ids = [
      for (final s in statuses)
        if (s.status != StageStatus.completed) s.stageId,
    ];
    final list = <LearningPathStageModel>[];
    for (final id in ids) {
      final stage = _path?.stages.firstWhereOrNull((s) => s.id == id);
      if (stage != null) list.add(stage);
      if (list.length >= 3) break;
    }
    return list;
  }

  int _completedCount() {
    return _model?.stages
            .where((s) => s.status == StageStatus.completed)
            .length ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final total = _model?.stages.length ?? 0;
    final completed = _completedCount();
    final percent = total == 0 ? 0 : (completed / total * 100).round();
    final streak = _streak;
    final streakText = streak != null && streak.currentStreak > 0
        ? '🔥 ${streak.currentStreak}-day streak'
        : null;
    final preview = _previewStages();
    final path = _path!;
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LearningPathStageListScreen(
                stages: path.stages,
                sections: path.sections,
              ),
            ),
          );
        },
        child: const Icon(Icons.list),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome back!', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('$percent% complete · $completed of $total stages'),
          if (streakText != null) Text(streakText),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _nextStage() == null ? null : _continueTraining,
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            child: const Text('Continue Training'),
          ),
          const SizedBox(height: 16),
          if (preview.isEmpty) const Text("Let's get started!"),
          for (final stage in preview) LearningPathStageTile(stage: stage),
        ],
      ),
    );
  }
}
