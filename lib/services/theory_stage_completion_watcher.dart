import 'dart:async';
import 'package:flutter/material.dart';

import 'theory_stage_progress_tracker.dart';

/// Watches scroll position and time spent on a theory stage
/// to automatically mark it as completed.
class TheoryStageCompletionWatcher {
  /// Creates a watcher.
  TheoryStageCompletionWatcher({
    TheoryStageProgressTracker? tracker,
    this.autoCompleteDelay = const Duration(seconds: 45),
  }) : tracker = tracker ?? TheoryStageProgressTracker.instance;

  /// Progress tracker used to mark completion.
  final TheoryStageProgressTracker tracker;

  /// Duration after which the stage is automatically marked
  /// completed if the user stays on the screen.
  final Duration autoCompleteDelay;

  Timer? _timer;
  ScrollController? _controller;
  VoidCallback? _listener;
  VoidCallback? _onCompleted;
  String? _stageId;
  bool _completed = false;

  /// Starts observing [controller] for [stageId].
  ///
  /// Optionally provide [context] to show a completion toast.
  void observe(
    String stageId,
    ScrollController controller, {
    BuildContext? context,
    VoidCallback? onCompleted,
  }) {
    dispose();
    _stageId = stageId;
    _controller = controller;
    _onCompleted = onCompleted;
    _listener = () => _onScroll(context);
    controller.addListener(_listener!);
    _timer = Timer(autoCompleteDelay, () => _markCompleted(context));
  }

  void _onScroll(BuildContext? context) {
    if (_completed) return;
    final c = _controller;
    if (c == null || !c.hasClients) return;
    final pos = c.position;
    if (!pos.hasContentDimensions) return;
    if (pos.pixels >= pos.maxScrollExtent) {
      _markCompleted(context);
    }
  }

  void _markCompleted(BuildContext? context) {
    if (_completed) return;
    final id = _stageId;
    if (id == null) return;
    _completed = true;
    tracker.markCompleted(id);
    _onCompleted?.call();
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Completed')),
      );
    }
  }

  /// Stops watching and cleans up listeners.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    if (_controller != null && _listener != null) {
      _controller!.removeListener(_listener!);
    }
    _controller = null;
    _listener = null;
    _onCompleted = null;
    _stageId = null;
    _completed = false;
  }
}
