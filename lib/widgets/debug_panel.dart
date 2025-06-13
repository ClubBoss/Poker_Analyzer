part of '../screens/poker_analyzer_screen.dart';

Widget _btn(String label, VoidCallback? onPressed) =>
    ElevatedButton(onPressed: onPressed, child: Text(label));

Widget _buttonsWrap(Map<String, VoidCallback?> actions) => Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in actions.entries) _btn(entry.key, entry.value),
      ],
    );

Widget _buttonsColumn(Map<String, VoidCallback?> actions) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in actions.entries) ...[
          Align(alignment: Alignment.centerLeft, child: _btn(entry.key, entry.value)),
          if (entry.key != actions.keys.last) const SizedBox(height: 12),
        ],
      ],
    );

class _ProcessingControls extends StatelessWidget {
  const _ProcessingControls(this.s);
  final _PokerAnalyzerScreenState s;

  @override
  Widget build(BuildContext context) {
    final disabled = s._pendingEvaluations.isEmpty;
    return _buttonsWrap({
      'Process Next':
          disabled || s._processingEvaluations ? null : s._processNextEvaluation,
      'Start Evaluation Processing':
          disabled || s._processingEvaluations ? null : s._processEvaluationQueue,
      s._pauseProcessingRequested ? 'Resume' : 'Pause':
          disabled || !s._processingEvaluations ? null : s._toggleEvaluationProcessingPause,
      'Cancel Evaluation Processing':
          !s._processingEvaluations && disabled ? null : s._cancelEvaluationProcessing,
      'Force Evaluation Restart': disabled ? null : s._forceRestartEvaluationProcessing,
    });
  }
}

class _SnapshotControls extends StatelessWidget {
  const _SnapshotControls(this.s);
  final _PokerAnalyzerScreenState s;

  @override
  Widget build(BuildContext context) {
    return _buttonsColumn({
      'Retry Failed Evaluations':
          s._failedEvaluations.isEmpty ? null : s._retryFailedEvaluations,
      'Export Snapshot Now': s._processingEvaluations
          ? null
          : () => s._exportEvaluationQueueSnapshot(showNotification: true),
      'Backup Queue Now': s._processingEvaluations
          ? null
          : () async {
              await s._backupEvaluationQueue();
              s._debugPanelSetState?.call(() {});
            },
    });
  }
}

class _QueueTools extends StatelessWidget {
  const _QueueTools(this.s);
  final _PokerAnalyzerScreenState s;

  @override
  Widget build(BuildContext context) {
    final noQueues = s._pendingEvaluations.isEmpty &&
        s._failedEvaluations.isEmpty &&
        s._completedEvaluations.isEmpty;
    return _buttonsWrap({
      'Import Evaluation Queue': s._importEvaluationQueue,
      'Restore Evaluation Queue': s._restoreEvaluationQueue,
      'Restore From Auto-Backup': s._restoreFromAutoBackup,
      'Bulk Import Evaluation Queue': s._bulkImportEvaluationQueue,
      'Bulk Import Backups': s._bulkImportEvaluationBackups,
      'Bulk Import Auto-Backups': s._bulkImportAutoBackups,
      'Import Queue Snapshot': s._importEvaluationQueueSnapshot,
      'Bulk Import Snapshots': s._bulkImportEvaluationSnapshots,
      'Export All Snapshots': s._exportAllEvaluationSnapshots,
      'Import Full Queue State': s._importFullEvaluationQueueState,
      'Restore Full Queue State': s._restoreFullEvaluationQueueState,
      'Export Full Queue State': s._exportFullEvaluationQueueState,
      'Export Current Queue Snapshot': s._exportEvaluationQueueSnapshot,
      'Quick Backup': s._quickBackupEvaluationQueue,
      'Import Quick Backups': s._importQuickBackups,
      'Export All Backups': s._exportAllEvaluationBackups,
      'Clear Pending': s._pendingEvaluations.isEmpty ? null : s._clearPendingQueue,
      'Clear Failed': s._failedEvaluations.isEmpty ? null : s._clearFailedQueue,
      'Clear Completed': s._completedEvaluations.isEmpty ? null : s._clearCompletedQueue,
      'Clear Evaluation Queue':
          s._pendingEvaluations.isEmpty && s._completedEvaluations.isEmpty ? null : s._clearEvaluationQueue,
      'Remove Duplicates': noQueues ? null : s._removeDuplicateEvaluations,
      'Resolve Conflicts': noQueues ? null : s._resolveQueueConflicts,
      'Sort Queues': noQueues ? null : s._sortEvaluationQueues,
      'Clear Completed Evaluations':
          s._completedEvaluations.isEmpty ? null : s._clearCompletedEvaluations,
    });
  }
}
