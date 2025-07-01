import 'pack_generator_service.dart';

final Map<String, double> _equity = {
  for (int i = 0; i < PackGeneratorService.handRanking.length; i++)
    PackGeneratorService.handRanking[i]:
        0.85 - i * (0.55 / (PackGeneratorService.handRanking.length - 1))
};

double computePushEV({
  required int heroBbStack,
  required int bbCount,
  required String heroHand,
  required int anteBb,
}) {
  final eq = _equity[heroHand] ?? 0.5;
  final pot = bbCount * anteBb + 1.5;
  final bet = heroBbStack.toDouble();
  return eq * pot - (1 - eq) * bet;
}
