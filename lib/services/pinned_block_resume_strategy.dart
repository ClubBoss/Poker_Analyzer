import '../models/resume_target.dart';
import '../models/theory_block_model.dart';
import 'pinned_block_tracker_service.dart';
import 'theory_block_library_service.dart';
import 'theory_path_completion_evaluator_service.dart';
import 'user_progress_service.dart';
import 'resume_strategy.dart';

class PinnedBlockResumeStrategy implements ResumeStrategy {
  PinnedBlockResumeStrategy({
    PinnedBlockTrackerService? tracker,
    TheoryBlockLibraryService? library,
    TheoryPathCompletionEvaluatorService? evaluator,
  })  : tracker = tracker ?? PinnedBlockTrackerService.instance,
        library = library ?? TheoryBlockLibraryService.instance,
        evaluator = evaluator ??
            TheoryPathCompletionEvaluatorService(
              userProgress: UserProgressService.instance,
            );

  final PinnedBlockTrackerService tracker;
  final TheoryBlockLibraryService library;
  final TheoryPathCompletionEvaluatorService evaluator;

  @override
  Future<ResumeTarget?> getResumeTarget() async {
    final ids = await tracker.getPinnedBlockIds();
    if (ids.isEmpty) return null;
    await library.loadAll();

    final entries = <_Entry>[];
    for (final id in ids) {
      final TheoryBlockModel? block = library.getById(id);
      if (block == null) continue;
      if (await evaluator.isBlockCompleted(block)) continue;
      final time = await tracker.getLastPinTime(id);
      if (time == null) continue;
      entries.add(_Entry(block.id, time));
    }
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.time.compareTo(a.time));
    return ResumeTarget(entries.first.id, ResumeType.block);
  }
}

class _Entry {
  _Entry(this.id, this.time);
  final String id;
  final DateTime time;
}
