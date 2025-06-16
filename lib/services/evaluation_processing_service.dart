import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/action_evaluation_request.dart';
import 'evaluation_queue_service.dart';
import 'retry_evaluation_service.dart';
import 'evaluation_executor_service.dart';
import 'backup_manager_service.dart';
import 'debug_panel_preferences.dart';

/// Manages processing of the evaluation queue.
class EvaluationProcessingService {
  EvaluationProcessingService({
    required this.queueService,
    required this.debugPrefs,
    this.backupManager,
    this.debugPanelCallback,
    EvaluationExecutorService? executorService,
    RetryEvaluationService? retryService,
  }) {
    _executorService = executorService ?? EvaluationExecutorService();
    _retryService =
        retryService ?? RetryEvaluationService(executorService: _executorService);
    debugPrefs.addListener(_onPrefsChanged);
    _initFuture = _initialize();
    queueService.debugPanelCallback = debugPanelCallback;
  }

  final EvaluationQueueService queueService;
  final DebugPanelPreferences debugPrefs;
  BackupManagerService? backupManager;

  late final EvaluationExecutorService _executorService;
  late final RetryEvaluationService _retryService;

  late final Future<void> _initFuture;

  bool processing = false;
  bool pauseRequested = false;
  bool cancelRequested = false;
  int processingDelay = 500;

  VoidCallback? debugPanelCallback;

  bool get snapshotRetentionEnabled => queueService.snapshotRetentionEnabled;
  set snapshotRetentionEnabled(bool v) => queueService.snapshotRetentionEnabled = v;

  void _onPrefsChanged() {
    snapshotRetentionEnabled = debugPrefs.snapshotRetentionEnabled;
    processingDelay = debugPrefs.processingDelay;
  }

  Future<void> _initialize() async {
    await debugPrefs.loadSnapshotRetention();
    await debugPrefs.loadProcessingDelay();
    _onPrefsChanged();
  }

  Future<bool> _processSingleEvaluation(ActionEvaluationRequest req) async {
    return _retryService.processEvaluation(req);
  }

  Future<void> processQueue() async {
    await _initFuture;
    if (processing ||
        await queueService.queueLock.synchronized(() => queueService.pending.isEmpty)) return;
    processing = true;
    while (await queueService.queueLock.synchronized(() => queueService.pending.isNotEmpty)) {
      if (pauseRequested || cancelRequested) break;
      final req = await queueService.queueLock.synchronized(() => queueService.pending.first);
      await Future.delayed(Duration(milliseconds: processingDelay));
      if (cancelRequested) break;
      if (await queueService.queueLock.synchronized(() => queueService.pending.isEmpty)) break;
      final success = await _processSingleEvaluation(req);
      await queueService.queueLock.synchronized(() {
        if (queueService.pending.isNotEmpty) {
          queueService.pending.removeAt(0);
        }
      });
      (success ? queueService.completed : queueService.failed).add(req);
      if (success) {
        await queueService.saveQueueSnapshot(showNotification: false);
        backupManager?.scheduleSnapshotExport();
      }
      await queueService.persist();
      if (pauseRequested || cancelRequested) break;
    }
    processing = false;
    pauseRequested = false;
    cancelRequested = false;
    await queueService.persist();
    debugPanelCallback?.call();
  }

  Future<void> togglePauseProcessing() async {
    pauseRequested = !pauseRequested;
    if (!pauseRequested && !processing && queueService.pending.isNotEmpty) {
      await processQueue();
    }
  }

  Future<void> cancelProcessing() async {
    cancelRequested = true;
    pauseRequested = false;
    await queueService.queueLock.synchronized(queueService.pending.clear);
    processing = false;
    await queueService.persist();
    debugPanelCallback?.call();
  }

  Future<void> forceRestartProcessing() async {
    if (processing) {
      cancelRequested = true;
      pauseRequested = false;
      while (processing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    processing = false;
    cancelRequested = false;
    if (queueService.pending.isNotEmpty) {
      await processQueue();
    }
  }

  void cleanup() {
    debugPrefs.removeListener(_onPrefsChanged);
    backupManager?.dispose();
  }
}
