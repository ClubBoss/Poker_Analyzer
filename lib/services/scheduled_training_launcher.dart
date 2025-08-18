import 'package:flutter/material.dart';

import '../main.dart';
import 'scheduled_training_queue_service.dart';
import 'pack_library_service.dart';
import 'training_session_launcher.dart';

/// Automatically launches the first queued training pack if available.
class ScheduledTrainingLauncher {
  final ScheduledTrainingQueueService queue;
  final PackLibraryService library;
  final TrainingSessionLauncher launcher;

  const ScheduledTrainingLauncher({
    ScheduledTrainingQueueService? queue,
    PackLibraryService? library,
    this.launcher = const TrainingSessionLauncher(),
  }) : queue = queue ?? ScheduledTrainingQueueService.instance,
       library = library ?? PackLibraryService.instance;

  /// Launches the next scheduled pack if one is queued.
  Future<void> launchNext() async {
    if (!queue.hasItems) return;
    final id = await queue.pop();
    if (id == null) return;
    final pack = await library.getById(id);
    if (pack == null) return;
    final ctx = navigatorKey.currentContext;
    if (ctx != null && pack.tags.isNotEmpty) {
      await showDialog<void>(
        context: ctx,
        builder: (_) => AlertDialog(
          content: Text('Auto-recovery in progress for ${pack.tags.first}'),
        ),
      );
    }
    await launcher.launch(pack);
  }
}
