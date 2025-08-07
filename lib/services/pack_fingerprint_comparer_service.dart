import '../models/training_pack_model.dart';
import '../models/action_entry.dart';
import 'board_texture_classifier.dart';
import 'dart:math';

/// Data class representing a training pack fingerprint.
class PackFingerprint {
  final Set<String> tags;
  final Set<String> boardTextures;
  final List<String> actionLines;
  final int spotCount;

  const PackFingerprint({
    required this.tags,
    required this.boardTextures,
    required this.actionLines,
    required this.spotCount,
  });
}

/// Result describing similarity between two packs.
class PackSimilarityResult {
  final TrainingPackModel a;
  final TrainingPackModel b;
  final double similarity;

  const PackSimilarityResult(this.a, this.b, this.similarity);
}

/// Computes and compares fingerprints of training packs to detect duplicates.
class PackFingerprintComparerService {
  final BoardTextureClassifier _classifier;

  const PackFingerprintComparerService({BoardTextureClassifier? classifier})
      : _classifier = classifier ?? const BoardTextureClassifier();

  /// Generates a fingerprint capturing high-level structure of [pack].
  PackFingerprint generatePackFingerprint(TrainingPackModel pack) {
    final tags = <String>{
      for (final t in pack.tags) t.trim().toLowerCase(),
    };
    final boardTextures = <String>{};
    final actionLines = <String>[];

    for (final spot in pack.spots) {
      tags.addAll(spot.tags.map((t) => t.trim().toLowerCase()));

      if (spot.board.length >= 3) {
        final flop = spot.board.take(3).join();
        boardTextures.addAll(_classifier.classify(flop));
      }

      final actions = <ActionEntry>[];
      final entries = spot.hand.actions.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final kv in entries) {
        for (final a in kv.value) {
          actions.add(a);
        }
      }
      final line = actions.map((a) => a.action).join('-');
      if (line.isNotEmpty) actionLines.add(line);
    }

    actionLines.sort();
    return PackFingerprint(
      tags: tags,
      boardTextures: boardTextures,
      actionLines: actionLines,
      spotCount: pack.spots.length,
    );
  }

  /// Computes whether fingerprints [a] and [b] are similar enough.
  bool areSimilar(PackFingerprint a, PackFingerprint b,
      {double threshold = 0.8}) {
    return _similarityScore(a, b) >= threshold;
  }

  /// Finds similar or duplicate packs within [packs].
  List<PackSimilarityResult> findDuplicates(List<TrainingPackModel> packs,
      {double threshold = 0.8}) {
    final fps = <TrainingPackModel, PackFingerprint>{};
    for (final p in packs) {
      fps[p] = generatePackFingerprint(p);
    }
    final results = <PackSimilarityResult>[];
    for (var i = 0; i < packs.length; i++) {
      for (var j = i + 1; j < packs.length; j++) {
        final p1 = packs[i];
        final p2 = packs[j];
        final sim = _similarityScore(fps[p1]!, fps[p2]!);
        if (sim >= threshold) {
          results.add(PackSimilarityResult(p1, p2, sim));
        }
      }
    }
    return results;
  }

  double _similarityScore(PackFingerprint a, PackFingerprint b) {
    final tagScore = _jaccard(a.tags, b.tags);
    final boardScore = _jaccard(a.boardTextures, b.boardTextures);
    final actionScore =
        _jaccard(a.actionLines.toSet(), b.actionLines.toSet());
    final countScore = _countScore(a.spotCount, b.spotCount);
    return (tagScore + boardScore + actionScore + countScore) / 4.0;
  }

  double _jaccard(Set<String> a, Set<String> b) {
    if (a.isEmpty && b.isEmpty) return 1.0;
    final inter = a.intersection(b).length.toDouble();
    final union = a.union(b).length.toDouble();
    return union == 0 ? 0 : inter / union;
  }

  double _countScore(int a, int b) {
    if (a == 0 && b == 0) return 1.0;
    final minC = min(a, b).toDouble();
    final maxC = max(a, b).toDouble();
    return maxC == 0 ? 0 : minC / maxC;
  }
}

