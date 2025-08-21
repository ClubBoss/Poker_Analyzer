import 'package:collection/collection.dart';

import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/action_entry.dart';
import 'training_pack_audit_log_service.dart';

/// Analyzes [TrainingPackModel]s and enriches their metadata with
/// computed characteristics such as difficulty, street coverage and stack
/// distribution.
class TrainingPackMetadataEnricherService {
  final TrainingPackAuditLogService _audit;

  TrainingPackMetadataEnricherService({TrainingPackAuditLogService? audit})
    : _audit = audit ?? TrainingPackAuditLogService();

  /// Returns a new [TrainingPackModel] with the metadata field populated
  /// with derived attributes. If the metadata changes, an audit entry is
  /// recorded via [_audit].
  Future<TrainingPackModel> enrich(
    TrainingPackModel pack, {
    String userId = 'system',
  }) async {
    final newMeta = Map<String, dynamic>.from(pack.metadata);

    final analysis = _analyze(pack.spots);
    newMeta
      ..addAll(analysis)
      ..['numSpots'] = pack.spots.length;

    final newPack = TrainingPackModel(
      id: pack.id,
      title: pack.title,
      spots: pack.spots,
      tags: pack.tags,
      metadata: newMeta,
    );

    if (!const DeepCollectionEquality().equals(pack.metadata, newMeta)) {
      await _audit.recordChange(pack, newPack, userId: userId);
    }

    return newPack;
  }

  Map<String, dynamic> _analyze(List<TrainingPackSpot> spots) {
    var maxStreet = 0;
    var hasLimp = false;
    var complexActions = false;
    double? minStack;
    double? maxStack;
    var stackTotal = 0.0;
    var stackCount = 0;

    for (final s in spots) {
      // track street coverage using spot.street and board length
      maxStreet = _maxStreet(maxStreet, s);

      // check for limped pots
      final preflop = s.hand.actions[0] ?? [];
      if (preflop.any((a) => a.action == 'limp')) {
        hasLimp = true;
      } else {
        final hasRaise = preflop.any(
          (a) => a.action == 'raise' || a.action == 'bet',
        );
        final hasCall = preflop.any((a) => a.action == 'call');
        if (!hasRaise && hasCall) hasLimp = true;
      }

      // inspect actions for complexity
      if (!complexActions) {
        for (final list in s.hand.actions.values) {
          if (list.any(_isComplexAction)) {
            complexActions = true;
            break;
          }
        }
      }

      // stack spread using hero stack
      final heroKey = s.hand.heroIndex.toString();
      final stack = s.hand.stacks[heroKey] ?? 0;
      minStack = (minStack == null)
          ? stack
          : (stack < minStack ? stack : minStack);
      maxStack = (maxStack == null)
          ? stack
          : (stack > maxStack ? stack : maxStack);
      stackTotal += stack;
      stackCount++;
    }

    final avgStack = stackCount > 0 ? stackTotal / stackCount : 0.0;
    final difficultyScore =
        (avgStack > 40 ? 1 : 0) +
        (maxStreet >= 2 ? 1 : 0) +
        (complexActions ? 1 : 0);

    final difficulty = difficultyScore >= 3
        ? 'hard'
        : difficultyScore >= 1
        ? 'medium'
        : 'easy';

    final streets = maxStreet >= 3
        ? 'river'
        : maxStreet >= 1
        ? 'flop+turn'
        : 'preflop';

    return {
      'difficulty': difficulty,
      'streets': streets,
      'stackSpread': {'min': minStack ?? 0, 'max': maxStack ?? 0},
      'hasLimpedPots': hasLimp,
    };
  }

  int _maxStreet(int currentMax, TrainingPackSpot s) {
    var street = s.street;
    if (s.board.length >= 5) {
      street = street < 3 ? 3 : street;
    } else if (s.board.length >= 4) {
      street = street < 2 ? 2 : street;
    } else if (s.board.length >= 3) {
      street = street < 1 ? 1 : street;
    }
    return street > currentMax ? street : currentMax;
  }

  bool _isComplexAction(ActionEntry a) {
    const advanced = {
      'raise',
      'bet',
      'check-raise',
      '3bet',
      '4bet',
      'push',
      'allin',
    };
    return advanced.contains(a.action.toLowerCase());
  }
}
