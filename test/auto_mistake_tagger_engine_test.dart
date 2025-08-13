import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/auto_mistake_tagger_engine.dart';
import 'package:poker_analyzer/models/mistake_tag.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = AutoMistakeTaggerEngine();

  TrainingSpotAttempt attempt({
    required String user,
    required String correct,
    double ev = 1.0,
    HeroPosition pos = HeroPosition.btn,
    int stack = 15,
  }) {
    final spot = TrainingPackSpot(
      id: 's',
      hand: HandData(position: pos, stacks: {'0': stack.toDouble()}),
      evalResult: EvaluationResult(
        correct: false,
        expectedAction: correct,
        userEquity: 0,
        expectedEquity: 0,
      ),
    );
    return TrainingSpotAttempt(
      spot: spot,
      userAction: user,
      correctAction: correct,
      evDiff: ev,
    );
  }

  test('btn overfold classified', () {
    final a =
        attempt(user: 'fold', correct: 'push', pos: HeroPosition.btn, ev: 1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.overfoldBtn));
    expect(tags, contains(MistakeTag.missedEvPush));
  });

  test('loose call bb classified', () {
    final a =
        attempt(user: 'call', correct: 'fold', pos: HeroPosition.bb, ev: -1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.looseCallBb));
  });

  test('loose call sb classified', () {
    final a =
        attempt(user: 'call', correct: 'fold', pos: HeroPosition.sb, ev: -1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.looseCallSb));
  });

  test('loose call co classified', () {
    final a =
        attempt(user: 'call', correct: 'fold', pos: HeroPosition.co, ev: -1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.looseCallCo));
  });

  test('overpush classified', () {
    final a =
        attempt(user: 'push', correct: 'fold', pos: HeroPosition.utg, ev: -1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.overpush));
  });

  test('missed call classified', () {
    final a =
        attempt(user: 'fold', correct: 'call', pos: HeroPosition.bb, ev: 1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.missedEvCall));
  });

  test('missed raise classified', () {
    final a =
        attempt(user: 'call', correct: 'raise', pos: HeroPosition.co, ev: 2);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.missedEvRaise));
  });

  test('short stack overfold classified', () {
    final a = attempt(
        user: 'fold', correct: 'push', pos: HeroPosition.sb, stack: 8, ev: 1);
    final tags = engine.tag(a);
    expect(tags, contains(MistakeTag.overfoldShortStack));
  });
}
