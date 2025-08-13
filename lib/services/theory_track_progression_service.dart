import '../models/theory_block_model.dart';
import '../models/theory_track_model.dart';
import 'theory_path_completion_evaluator_service.dart';

/// Determines which blocks of a [TheoryTrackModel] are currently unlocked.
class TheoryTrackProgressionService {
  final TheoryPathCompletionEvaluatorService evaluator;

  const TheoryTrackProgressionService({required this.evaluator});

  /// Returns blocks that are unlocked based on sequential completion.
  Future<List<TheoryBlockModel>> getUnlockedBlocks(
      TheoryTrackModel track) async {
    final unlocked = <TheoryBlockModel>[];
    for (var i = 0; i < track.blocks.length; i++) {
      final block = track.blocks[i];
      if (i == 0) {
        unlocked.add(block);
        continue;
      }
      final prev = track.blocks[i - 1];
      final done = await evaluator.isBlockCompleted(prev);
      if (done) {
        unlocked.add(block);
      } else {
        break;
      }
    }
    return unlocked;
  }

  /// Returns true if [block] is unlocked within [track].
  Future<bool> isBlockUnlocked(
      TheoryTrackModel track, TheoryBlockModel block) async {
    final unlocked = await getUnlockedBlocks(track);
    return unlocked.any((b) => b.id == block.id);
  }
}
