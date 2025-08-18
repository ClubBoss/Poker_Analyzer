import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';

/// Provides sampling of large training packs to create a smaller
/// representative subset.
class TrainingPackSampler {
  const TrainingPackSampler();

  /// Returns a new [TrainingPackTemplateV2] containing at most [maxSpots]
  /// spots sampled from [fullPack].
  TrainingPackTemplateV2 sample(
    TrainingPackTemplateV2 fullPack, {
    int maxSpots = 20,
  }) {
    if (fullPack.spots.length <= maxSpots) return fullPack;

    final spots = List<TrainingPackSpot>.from(fullPack.spots);

    // Group spots by hero position.
    final posGroups = <HeroPosition, List<TrainingPackSpot>>{};
    for (final s in spots) {
      posGroups.putIfAbsent(s.hand.position, () => []).add(s);
    }

    final selected = <TrainingPackSpot>[];

    // Ensure at least one spot from each position if available.
    for (final p in kPositionOrder) {
      final group = posGroups[p];
      if (group != null && group.isNotEmpty) {
        selected.add(group.removeAt(0));
        if (selected.length >= maxSpots) break;
      }
    }

    if (selected.length < maxSpots) {
      // Diversity buckets for board length and stack size.
      String boardBucket(TrainingPackSpot s) {
        final n = s.hand.board.length;
        if (n >= 5) return 'river';
        if (n == 4) return 'turn';
        if (n >= 3) return 'flop';
        return 'preflop';
      }

      int stackBucket(TrainingPackSpot s) {
        final stack = s.hand.stacks['${s.hand.heroIndex}']?.toInt() ?? 0;
        if (stack <= 10) return 10;
        if (stack <= 20) return 20;
        if (stack <= 40) return 40;
        return 100;
      }

      final usedComb = <String>{};

      // Round-robin through remaining groups to preserve position balance.
      bool added;
      do {
        added = false;
        for (final p in kPositionOrder) {
          final group = posGroups[p];
          if (group == null || group.isEmpty) continue;
          final spot = group.removeAt(0);
          final key = '${p.name}-${boardBucket(spot)}-${stackBucket(spot)}';
          if (usedComb.add(key)) {
            selected.add(spot);
            added = true;
            if (selected.length >= maxSpots) break;
          }
          if (selected.length >= maxSpots) break;
        }
      } while (added && selected.length < maxSpots);

      // Fill up with any remaining spots if still below limit.
      if (selected.length < maxSpots) {
        final remaining = posGroups.values.expand((e) => e);
        for (final s in remaining) {
          selected.add(s);
          if (selected.length >= maxSpots) break;
        }
      }
    }

    // Sort final list for a polished UX.
    selected.sort((a, b) {
      final pa = kPositionOrder.indexOf(a.hand.position);
      final pb = kPositionOrder.indexOf(b.hand.position);
      if (pa != pb) return pa.compareTo(pb);
      final sa = a.hand.stacks['${a.hand.heroIndex}'] ?? 0;
      final sb = b.hand.stacks['${b.hand.heroIndex}'] ?? 0;
      return sa.compareTo(sb);
    });

    final map = fullPack.toJson();
    map['spots'] = [for (final s in selected) s.toJson()];
    map['spotCount'] = selected.length;
    final result = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );
    result.isSampledPack = true;
    return result;
  }
}
