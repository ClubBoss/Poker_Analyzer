// ASCII-only; pure Dart (no Flutter imports)

import 'live_ids.dart';

class LiveProgress {
  final int done;
  final int total;
  final List<String> remaining;
  const LiveProgress({
    required this.done,
    required this.total,
    required this.remaining,
  });
  double get pct => total == 0 ? 0.0 : done / total;
  @override
  String toString() => 'LiveProgress(done: $done, total: $total, pct: $pct)';
  @override
  bool operator ==(Object o) =>
      o is LiveProgress &&
      o.done == done &&
      o.total == total &&
      _listEq(o.remaining, remaining);
  @override
  int get hashCode => Object.hash(done, total, Object.hashAll(remaining));
}

bool _listEq(List a, List b) =>
    a.length == b.length &&
    Iterable.generate(a.length).every((i) => a[i] == b[i]);

/// Computes progress using SSOT list kLiveModuleIds.
LiveProgress computeLiveProgress(Set<String> modulesDone) {
  final total = kLiveModuleIds.length;
  final remaining = <String>[];
  int done = 0;
  for (final id in kLiveModuleIds) {
    if (modulesDone.contains(id)) {
      done++;
    } else {
      remaining.add(id);
    }
  }
  return LiveProgress(done: done, total: total, remaining: remaining);
}
