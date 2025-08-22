import 'package:collection/collection.dart';

import '../models/saved_hand.dart';

class SnapshotDiff {
  final Map<String, dynamic> forward;
  final Map<String, dynamic> backward;
  SnapshotDiff({required this.forward, required this.backward});
}

class DiffSnapshotService {
  static const _equality = DeepCollectionEquality();

  Map<String, dynamic> _diffMap(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final diff = <String, dynamic>{};
    final keys = {...a.keys, ...b.keys};
    for (final k in keys) {
      final av = a[k];
      final bv = b[k];
      if (_equality.equals(av, bv)) continue;
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

  SnapshotDiff compute(SavedHand oldSnap, SavedHand newSnap) {
    final oldMap = oldSnap.toJson();
    final newMap = newSnap.toJson();
    return SnapshotDiff(
      forward: _diffMap(oldMap, newMap),
      backward: _diffMap(newMap, oldMap),
    );
  }

  SavedHand apply(SavedHand base, Map<String, dynamic> diff) {
    final map = Map<String, dynamic>.from(base.toJson());
    _applyMap(map, diff);
    return SavedHand.fromJson(map);
  }
}
