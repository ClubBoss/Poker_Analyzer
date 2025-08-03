import 'package:flutter/material.dart';

import 'learning_path_summary_cache_v2.dart';
import 'pack_library_service.dart';
import 'training_session_launcher.dart';
import '../utils/snackbar_util.dart';

/// Launches the next available stage for a learning path.
class LearningPathLauncherService {
  final LearningPathSummaryCache cache;
  final PackLibraryService library;
  final TrainingSessionLauncher launcher;

  LearningPathLauncherService({
    required this.cache,
    PackLibraryService? library,
    TrainingSessionLauncher launcher = const TrainingSessionLauncher(),
  })  : library = library ?? PackLibraryService.instance,
        launcher = launcher;

  /// Loads [pathId] summary and starts training for the next stage if possible.
  Future<void> launchNextStage(String pathId, BuildContext context) async {
    await cache.refresh();
    final summary = cache.summaryById(pathId);
    if (summary == null) {
      SnackbarUtil.showMessage(context, 'Learning path not found');
      return;
    }

    final stage = summary.nextStageToTrain;
    if (stage == null) {
      SnackbarUtil.showMessage(context, 'All stages completed');
      return;
    }

    final template = await library.getById(stage.packId);
    if (template == null) {
      SnackbarUtil.showMessage(context, 'Training pack not found');
      return;
    }

    await launcher.launch(template);
  }
}
