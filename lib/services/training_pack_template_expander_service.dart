import 'package:uuid/uuid.dart';

import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_spot.dart';

/// Expands a [TrainingPackTemplateSet] into concrete [TrainingPackSpot]s.
///
/// Each variation defines a map of property names to a list of values. The
/// expander generates the cartesian product of all values within a variation
/// and applies them to the base spot, producing a unique spot for every
/// combination. Tags from the base spot are inherited by all generated spots,
/// and the base `theoryLink` is preserved. The original spot `id` is stored in
/// [TrainingPackSpot.templateSourceId].
class TrainingPackTemplateExpanderService {
  const TrainingPackTemplateExpanderService();

  /// Generates all spots described by [set].
  List<TrainingPackSpot> expand(TrainingPackTemplateSet set) {
    final results = <TrainingPackSpot>[];
    if (set.variations.isEmpty) {
      results.add(_cloneBase(set.baseSpot));
      return results;
    }

    for (final variation in set.variations) {
      final combos = _cartesian(variation);
      for (final combo in combos) {
        final spot = _cloneBase(set.baseSpot);
        combo.forEach((key, value) {
          switch (key) {
            case 'board':
              final board = List<String>.from(value as List);
              spot.board = board;
              spot.hand.board = List<String>.from(board);
              break;
            case 'heroStack':
              final stack = (value as num).toDouble();
              spot.hand.stacks = {...spot.hand.stacks, '0': stack};
              break;
            case 'tags':
              final tags = [for (final t in value as List) t.toString()];
              final merged = {...set.baseSpot.tags, ...tags};
              spot.tags = merged.toList();
              break;
            default:
              spot.meta[key] = value;
          }
        });
        results.add(spot);
      }
    }
    return results;
  }

  TrainingPackSpot _cloneBase(TrainingPackSpot base) {
    final json = Map<String, dynamic>.from(base.toJson());
    json['id'] = const Uuid().v4();
    final copy = TrainingPackSpot.fromJson(json);
    copy.templateSourceId = base.id;
    copy.tags = List<String>.from(base.tags);
    copy.theoryLink = base.theoryLink;
    return copy;
  }

  List<Map<String, dynamic>> _cartesian(Map<String, List<dynamic>> input) {
    var result = <Map<String, dynamic>>[{}];
    input.forEach((key, values) {
      final next = <Map<String, dynamic>>[];
      for (final combo in result) {
        for (final v in values) {
          final map = Map<String, dynamic>.from(combo);
          map[key] = v;
          next.add(map);
        }
      }
      result = next;
    });
    return result;
  }
}
