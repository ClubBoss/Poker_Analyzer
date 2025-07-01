import 'pack_generator_service.dart';

double _handEquity(String hand) {
  final i = PackGeneratorService.handRanking.indexOf(hand);
  if (i < 0) return 0.5;
  return 0.85 - i * (0.55 / (PackGeneratorService.handRanking.length - 1));
}

double computeIcmPushEV({
  required List<int> chipStacksBb,
  required int heroIndex,
  required String heroHand,
  required double chipPushEv,
}) {
  final heroStack = chipStacksBb[heroIndex].toDouble();
  final total = chipStacksBb.fold<double>(0, (p, e) => p + e);
  final eq = _handEquity(heroHand);
  final pot = (chipPushEv + (1 - eq) * heroStack) / eq;
  final pre = heroStack / total;
  final post = (heroStack + pot) / total;
  final factor = pre / post;
  return chipPushEv / total * factor;
}

