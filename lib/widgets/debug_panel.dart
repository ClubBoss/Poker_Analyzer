part of '../screens/poker_analyzer_screen.dart';

import 'package:flutter/material.dart';

const _vGap = SizedBox(height: 12);

Widget _btn(String label, VoidCallback? onPressed) =>
    ElevatedButton(onPressed: onPressed, child: Text(label));

Widget _buttonsWrap(Map<String, VoidCallback?> actions) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in actions.entries) _btn(entry.key, entry.value),
    ],
  );
}

Widget _buttonsColumn(Map<String, VoidCallback?> actions) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final entry in actions.entries) ...[
        Align(alignment: Alignment.centerLeft, child: _btn(entry.key, entry.value)),
        if (entry.key != actions.keys.last) _vGap,
      ],
    ],
  );
}

class _ProcessingControls extends StatelessWidget {
  final bool queueEmpty;
  final bool processing;
  final bool pauseRequested;
  final VoidCallback? processNext;
  final VoidCallback? startProcessing;
  final VoidCallback? togglePause;
  final VoidCallback? cancelProcessing;
  final VoidCallback? forceRestart;

  const _ProcessingControls({
    required this.queueEmpty,
    required this.processing,
    required this.pauseRequested,
    required this.processNext,
    required this.startProcessing,
    required this.togglePause,
    required this.cancelProcessing,
    required this.forceRestart,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = queueEmpty;
    return _buttonsWrap({
      'Process Next': disabled || processing ? null : processNext,
      'Start Evaluation Processing':
          disabled || processing ? null : startProcessing,
      pauseRequested ? 'Resume' : 'Pause':
          disabled || !processing ? null : togglePause,
      'Cancel Evaluation Processing':
          !processing && disabled ? null : cancelProcessing,
      'Force Evaluation Restart': disabled ? null : forceRestart,
    });
  }
}

class _SnapshotControls extends StatelessWidget {
  final bool hasFailed;
  final bool processing;
  final VoidCallback? retryFailed;
  final VoidCallback? exportSnapshot;
  final Future<void> Function()? backupQueue;

  const _SnapshotControls({
    required this.hasFailed,
    required this.processing,
    required this.retryFailed,
    required this.exportSnapshot,
    required this.backupQueue,
  });

  @override
  Widget build(BuildContext context) {
    return _buttonsColumn({
      'Retry Failed Evaluations': hasFailed ? retryFailed : null,
      'Export Snapshot Now': processing ? null : exportSnapshot,
      'Backup Queue Now': processing
          ? null
          : () async {
              if (backupQueue != null) {
                await backupQueue!();
              }
            },
    });
  }
}

class _QueueTools extends StatelessWidget {
  final Map<String, VoidCallback?> actions;
  const _QueueTools({required this.actions});

  @override
  Widget build(BuildContext context) => _buttonsWrap(actions);
}

