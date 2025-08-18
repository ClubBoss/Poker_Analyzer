import 'package:collection/collection.dart';

class StateDiff {
  final Map<String, dynamic> forward;
  final Map<String, dynamic> backward;
  const StateDiff({required this.forward, required this.backward});
}

class DiffEngine {
  static const DeepCollectionEquality _eq = DeepCollectionEquality();

  Map<String, dynamic> _diffMap(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final diff = <String, dynamic>{};
    final keys = {...a.keys, ...b.keys};
    for (final k in keys) {
      final av = a[k];
      final bv = b[k];
      if (_eq.equals(av, bv)) continue;
      if (av is Map && bv is Map) {
        final sub = _diffMap(
          Map<String, dynamic>.from(av),
          Map<String, dynamic>.from(bv),
        );
        if (sub.isNotEmpty) diff[k] = sub;
      } else {
        diff[k] = bv;
      }
    }
    return diff;
  }

  void _applyMap(Map<String, dynamic> target, Map<String, dynamic> diff) {
    diff.forEach((k, v) {
      final tv = target[k];
      if (v is Map && tv is Map<String, dynamic>) {
        _applyMap(tv, Map<String, dynamic>.from(v));
      } else {
        target[k] = v;
      }
    });
  }

  StateDiff compute(
    Map<String, dynamic> oldState,
    Map<String, dynamic> newState,
  ) {
    return StateDiff(
      forward: _diffMap(oldState, newState),
      backward: _diffMap(newState, oldState),
    );
  }

  Map<String, dynamic> apply(
    Map<String, dynamic> base,
    Map<String, dynamic> diff,
  ) {
    final result = Map<String, dynamic>.from(base);
    _applyMap(result, diff);
    return result;
  }
}
