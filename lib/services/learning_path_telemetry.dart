import 'dart:io';

import '../models/learning_path_player_progress.dart';

/// Lightweight telemetry writer for learning path sessions.
class LearningPathTelemetry {
  const LearningPathTelemetry();

  Future<void> logSummary(
      {required String pathId, required LearningPathProgress progress}) async {
    final stagesCompleted =
        progress.stages.values.where((s) => s.completed).length;
    final handsPlayed =
        progress.stages.values.fold<int>(0, (a, b) => a + b.handsPlayed);
    final avgAcc = progress.stages.isEmpty
        ? 0.0
        : progress.stages.values
                .fold<double>(0, (a, b) => a + b.accuracy) /
            progress.stages.length;
    final line =
        'pathId=$pathId stagesCompleted=$stagesCompleted handsPlayed=$handsPlayed avgAccuracy=${avgAcc.toStringAsFixed(2)}\n';
    final file = File('autogen_report.log');
    await file.writeAsString(line, mode: FileMode.append, flush: true);
  }

  Future<void> logStageComplete({
    required String pathId,
    required String stageId,
    required StageProgress progress,
  }) async {
    final line =
        'stageComplete pathId=$pathId stageId=$stageId hands=${progress.handsPlayed} acc=${progress.accuracy.toStringAsFixed(2)}\n';
    final file = File('autogen_report.log');
    await file.writeAsString(line, mode: FileMode.append, flush: true);
  }
}

