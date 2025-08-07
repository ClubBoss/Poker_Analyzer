import 'package:flutter/foundation.dart';

/// Possible statuses for the autogen pipeline.
enum AutogenPipelineStatus {
  ready,
  paused,
  publishing,
  error,
}

/// Service exposing the current state of the autogen pipeline.
class AutogenPipelineStateService {
  AutogenPipelineStateService._();

  static final ValueNotifier<AutogenPipelineStatus> _state =
      ValueNotifier(AutogenPipelineStatus.ready);

  /// Returns a [ValueNotifier] for the current pipeline state.
  static ValueNotifier<AutogenPipelineStatus> getCurrentState() => _state;

  // Additional methods for updating the state can be added here in future.
}

