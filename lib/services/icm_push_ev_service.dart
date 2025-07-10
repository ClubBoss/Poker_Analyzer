
double computeIcmPushEV({
  required List<int> chipStacksBb,
  required int heroIndex,
  required String heroHand,
  required double chipPushEv,
}) {
  double icmValue(List<double> stacks, int idx) {
    final payouts = [0.5, 0.3, 0.2];
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
  stacks[heroIndex] = (stacks[heroIndex] + chipPushEv).clamp(0, double.infinity);
  final post = icmValue(stacks, heroIndex);
  return post - pre;
}

