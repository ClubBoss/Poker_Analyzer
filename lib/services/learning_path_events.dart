import '../models/injected_path_module.dart';

/// Simple event hooks for learning path module lifecycle.
class LearningPathEvents {
  static void moduleInjected(String userId, InjectedPathModule module) {}
  static void moduleStarted(String userId, String moduleId) {}
  static void moduleCompleted(
    String userId,
    String moduleId,
    double passRate,
  ) {}
}
