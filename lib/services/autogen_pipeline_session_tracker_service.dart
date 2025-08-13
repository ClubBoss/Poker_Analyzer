import 'dart:async';

import '../models/autogen_step_status.dart';

/// Tracks progress of autogen steps for a session and exposes updates as a
/// stream.
class AutogenPipelineSessionTrackerService {
  AutogenPipelineSessionTrackerService._();

  static final AutogenPipelineSessionTrackerService _instance =
      AutogenPipelineSessionTrackerService._();

  factory AutogenPipelineSessionTrackerService() => _instance;
  static AutogenPipelineSessionTrackerService get instance => _instance;

  final Map<String, List<AutoGenStepStatus>> _sessionSteps = {};
  final Map<String, StreamController<List<AutoGenStepStatus>>> _controllers =
      {};

  Stream<List<AutoGenStepStatus>> watchSession(String sessionId) {
    final controller = _controllers.putIfAbsent(
      sessionId,
      () => StreamController<List<AutoGenStepStatus>>.broadcast(),
    );
    _sessionSteps.putIfAbsent(sessionId, () => []);
    return controller.stream;
  }

  void updateStep(String sessionId, AutoGenStepStatus status) {
    final steps = _sessionSteps.putIfAbsent(sessionId, () => []);
    steps.removeWhere((s) => s.stepName == status.stepName);
    steps.add(status);
    final controller = _controllers.putIfAbsent(
      sessionId,
      () => StreamController<List<AutoGenStepStatus>>.broadcast(),
    );
    controller.add(List.unmodifiable(steps));
  }

  void clearSession(String sessionId) {
    _controllers[sessionId]?.close();
    _controllers.remove(sessionId);
    _sessionSteps.remove(sessionId);
  }
}
