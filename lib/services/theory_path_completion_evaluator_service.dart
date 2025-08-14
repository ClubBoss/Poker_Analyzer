import '../models/theory_block_model.dart';
import 'user_progress_service.dart';

/// Possible completion states for a theory block.
enum CompletionStatus { notStarted, inProgress, completed }

/// Evaluates completion of theory blocks based on lesson and pack progress.
class TheoryPathCompletionEvaluatorService {
  final UserProgressService userProgress;

  const TheoryPathCompletionEvaluatorService({
    required this.userProgress,
  });

  /// Returns true if all lessons and packs in [block] are completed.
  Future<bool> isBlockCompleted(TheoryBlockModel block) async {
    return (await getBlockStatus(block)) == CompletionStatus.completed;
  }

  /// Computes completion percentage for [block] (0.0-1.0).
  Future<double> getBlockCompletionPercent(TheoryBlockModel block) async {
    final total = block.nodeIds.length + block.practicePackIds.length;
    if (total == 0) return 0.0;
    var done = 0;
    for (final id in block.nodeIds) {
      if (await userProgress.isTheoryLessonCompleted(id)) {
        done++;
      }
    }
    for (final id in block.practicePackIds) {
      if (await userProgress.isPackCompleted(id)) {
        done++;
      }
    }
    return done / total;
  }

  /// Derives high-level status for [block].
  Future<CompletionStatus> getBlockStatus(TheoryBlockModel block) async {
    final percent = await getBlockCompletionPercent(block);
    if (percent == 0) return CompletionStatus.notStarted;
    if (percent >= 1.0) return CompletionStatus.completed;
    return CompletionStatus.inProgress;
  }
}
