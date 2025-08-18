import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/weak_spot_recommendation_service.dart';
import 'package:poker_analyzer/services/player_progress_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:flutter/foundation.dart';

class _FakeSavedHandManagerService extends ChangeNotifier {
  final List hands;
  _FakeSavedHandManagerService();
}

class _FakePlayerProgressService extends ChangeNotifier {
  final Map<HeroPosition, PositionProgress> _progress;
  _FakePlayerProgressService(this._progress);
  Map<HeroPosition, PositionProgress> get progress => _progress;
}

void main() {
  test('recommendations sorted and buildPack follows logic', () async {
    final hands = _FakeSavedHandManagerService();
    final progress = _FakePlayerProgressService({
      HeroPosition.sb: const PositionProgress(
        hands: 10,
        correct: 7,
        ev: 0,
        icm: 0,
      ),
      HeroPosition.bb: const PositionProgress(
        hands: 10,
        correct: 6,
        ev: -1,
        icm: 0,
      ),
      HeroPosition.co: const PositionProgress(
        hands: 10,
        correct: 5,
        ev: 0,
        icm: -1,
      ),
    });
    final service = WeakSpotRecommendationService(
      hands: hands,
      progress: progress,
    );
    final order = service.recommendations.map((e) => e.position).toList();
    expect(order, [HeroPosition.co, HeroPosition.bb, HeroPosition.sb]);
    final tpl = await service.buildPack(HeroPosition.co);
    final rec = service.recommendations.first;
    var stack = (15 + ((0.5 - rec.accuracy) * 10)).round();
    stack += rec.ev < 0 ? 1 : 0;
    stack += rec.icm < 0 ? 1 : 0;
    stack = stack.clamp(5, 25);
    expect(tpl?.heroPos, HeroPosition.co);
    expect(tpl?.heroBbStack, stack);
    expect(tpl?.playerStacksBb, [stack, stack]);
  });
}
