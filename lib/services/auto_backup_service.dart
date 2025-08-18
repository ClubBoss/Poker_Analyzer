import 'dart:async';

import '../models/action_evaluation_request.dart';
import 'backup_file_manager.dart';
import 'evaluation_queue_service.dart';
import 'evaluation_queue_serializer.dart';

/// Handles automatic backup timer and cleanup operations.
class AutoBackupService {
  AutoBackupService({
    required this.queueService,
    required this.fileManager,
    required this.serializer,
  });

  final EvaluationQueueService queueService;
  final BackupFileManager fileManager;
  final EvaluationQueueSerializer serializer;

  List<ActionEvaluationRequest> get _pending => queueService.pending;
  List<ActionEvaluationRequest> get _failed => queueService.failed;
  List<ActionEvaluationRequest> get _completed => queueService.completed;

  Map<String, dynamic> _currentState() => serializer.encodeQueues(
    pending: _pending,
    failed: _failed,
    completed: _completed,
  );

  /// Starts periodic automatic backups of the evaluation queue.
  Future<void> startAutoBackupTimer() async {
    fileManager.startAutoBackupTimer(_currentState);
  }

  /// Disposes any resources used for automatic backups.
  void dispose() {
    fileManager.dispose();
  }

  /// Cleans up old automatic backup files using the default retention limit.
  Future<void> cleanupOldAutoBackups() async {
    await fileManager.cleanupOldAutoBackups();
  }
}
