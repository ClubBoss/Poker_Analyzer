import 'push_fold_ev_service.dart';

double computeIcmPushEV({
  required List<int> chipStacksBb,
  required int heroIndex,
  required String heroHand,
  required double chipPushEv,
  List<double> payouts = const [0.5, 0.3, 0.2],
}) {
  double icmValue(List<double> stacks, int idx) {
    double prob(int rank, List<double> s, int hero) {
      final total = s.fold<double>(0, (p, e) => p + e);
      if (rank == 1) return s[hero] / total;
      double r = 0;
      for (var i = 0; i < s.length; i++) {
        if (i == hero) continue;
        final next = List<double>.from(s)..removeAt(i);
        final hi = hero > i ? hero - 1 : hero;
        r += s[i] / total * prob(rank - 1, next, hi);
      }
      return r;
    }

    double val = 0;
    for (var i = 0; i < payouts.length && i < stacks.length; i++) {
      val += payouts[i] * prob(i + 1, stacks, idx);
    }
    return val;
  }

  final stacks = [for (final s in chipStacksBb) s.toDouble()];
  final pre = icmValue(stacks, heroIndex);
  stacks[heroIndex] =
      (stacks[heroIndex] + chipPushEv).clamp(0, double.infinity);
  final post = icmValue(stacks, heroIndex);
  return post - pre;
}

double computeLocalIcmPushEV({
  required List<int> chipStacksBb,
  required int heroIndex,
  required String heroHand,
  required int anteBb,
  List<double> payouts = const [0.5, 0.3, 0.2],
}) {
  final ev = computePushEV(
    heroBbStack: chipStacksBb[heroIndex],
    bbCount: chipStacksBb.length - 1,
    heroHand: heroHand,
    anteBb: anteBb,
  );
  return computeIcmPushEV(
    chipStacksBb: chipStacksBb,
    heroIndex: heroIndex,
    heroHand: heroHand,
    chipPushEv: ev,
    payouts: payouts,
  );
}

double computeMultiwayIcmEV({
  required List<int> chipStacksBb,
  required int heroIndex,
  required double chipPushEv,
  required List<int> callerIndices,
  List<double> payouts = const [0.5, 0.3, 0.2],
}) {
  double icmValue(List<double> stacks, int idx) {
    double prob(int rank, List<double> s, int hero) {
      final total = s.fold<double>(0, (p, e) => p + e);
      if (rank == 1) return s[hero] / total;
      double r = 0;
      for (var i = 0; i < s.length; i++) {
        if (i == hero) continue;
        final next = List<double>.from(s)..removeAt(i);
        final hi = hero > i ? hero - 1 : hero;
        r += s[i] / total * prob(rank - 1, next, hi);
      }
      return r;
    }

    double val = 0;
    for (var i = 0; i < payouts.length && i < stacks.length; i++) {
      val += payouts[i] * prob(i + 1, stacks, idx);
    }
    return val;
  }

  final stacks = [for (final s in chipStacksBb) s.toDouble()];
  final pre = icmValue(stacks, heroIndex);
  final delta = chipPushEv / callerIndices.length;
  stacks[heroIndex] =
      (stacks[heroIndex] + chipPushEv).clamp(0, double.infinity);
  for (final i in callerIndices) {
    if (i != heroIndex) {
      stacks[i] = (stacks[i] - delta).clamp(0, double.infinity);
    }
  }
  final post = icmValue(stacks, heroIndex);
  return post - pre;
}
