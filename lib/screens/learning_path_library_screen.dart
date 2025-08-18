import 'package:flutter/material.dart';

import '../repositories/learning_path_repository.dart';
import '../models/learning_path_track_model.dart';
import '../models/learning_path_template_v2.dart';
import '../models/learning_path_progress.dart';
import '../widgets/track_section_widget.dart';
import '../services/learning_path_stage_progress_engine.dart';
import '../services/learning_path_stage_unlock_engine.dart';
import '../services/session_log_service.dart';
import 'package:provider/provider.dart';

/// Displays all available learning path tracks and their paths.
class LearningPathLibraryScreen extends StatefulWidget {
  const LearningPathLibraryScreen({super.key});

  @override
  State<LearningPathLibraryScreen> createState() =>
      _LearningPathLibraryScreenState();
}

class _LearningPathLibraryScreenState extends State<LearningPathLibraryScreen> {
  late Future<Map<LearningPathTrackModel, List<LearningPathTemplateV2>>>
  _future;
  final _repo = LearningPathRepository();
  late SessionLogService _logs;
  late LearningPathStageProgressEngine _progressEngine;
  final _unlockEngine = const LearningPathStageUnlockEngine();
  Map<String, LearningPathProgress> _progress = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // will load in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _logs = context.read<SessionLogService>();
      _progressEngine = LearningPathStageProgressEngine(logs: _logs);
      _future = _load();
      _initialized = true;
    }
  }

  Future<Map<LearningPathTrackModel, List<LearningPathTemplateV2>>>
  _load() async {
    final map = await _repo.loadAllTracksWithPaths();
    await _computeProgress(map.values.expand((e) => e));
    return map;
  }

  Future<void> _computeProgress(Iterable<LearningPathTemplateV2> paths) async {
    final hands = <String, int>{};
    final correct = <String, int>{};
    for (final log in _logs.logs) {
      final count = log.correctCount + log.mistakeCount;
      hands.update(log.templateId, (v) => v + count, ifAbsent: () => count);
      correct.update(
        log.templateId,
        (v) => v + log.correctCount,
        ifAbsent: () => log.correctCount,
      );
    }
    final result = <String, LearningPathProgress>{};
    for (final path in paths) {
      final map = await _progressEngine.getStageProgress(path);
      final completed = <String>{};
      final unlocked = <String>{};
      for (final stage in path.stages) {
        final ratio = map[stage.packId] ?? 0.0;
        final played = hands[stage.packId] ?? 0;
        final corr = correct[stage.packId] ?? 0;
        final acc = played == 0 ? 0.0 : corr / played * 100;
        if (played >= stage.minHands &&
            acc >= stage.requiredAccuracy &&
            ratio >= 1.0) {
          completed.add(stage.id);
        }
      }
      for (final stage in path.stages) {
        if (_unlockEngine.isStageUnlocked(path, stage.id, completed)) {
          unlocked.add(stage.id);
        }
      }
      double accSum = 0.0;
      for (final id in completed) {
        final stage = path.stages.firstWhere((e) => e.id == id);
        final played = hands[stage.packId] ?? 0;
        final corr = correct[stage.packId] ?? 0;
        final acc = played == 0 ? 0.0 : corr / played * 100;
        accSum += acc;
      }
      final avgAcc = completed.isEmpty ? 0.0 : accSum / completed.length;
      String? current;
      for (final s in path.stages) {
        if (unlocked.contains(s.id) && !completed.contains(s.id)) {
          current = s.id;
          break;
        }
      }
      result[path.id] = LearningPathProgress(
        completedStages: completed.length,
        totalStages: path.stages.length,
        overallAccuracy: avgAcc,
        currentStageId: current,
      );
    }
    setState(() => _progress = result);
  }

  Future<void> _reload() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
      Map<LearningPathTrackModel, List<LearningPathTemplateV2>>
    >(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const {};
        return Scaffold(
          appBar: AppBar(title: const Text('📚 Обучающие треки')),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
              ? const Center(child: Text('Нет доступных треков'))
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      for (final entry in data.entries)
                        TrackSectionWidget(
                          track: entry.key,
                          paths: entry.value,
                          progress: _progress,
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
