import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/mistake.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/evaluation_result.dart';
import 'package:poker_analyzer/services/mistake_categorization_engine.dart';
import 'package:poker_analyzer/widgets/poker_table_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = MistakeCategorizationEngine();

  TrainingPackSpot spot(String exp, {HeroPosition pos = HeroPosition.btn}) {
    return TrainingPackSpot(
      id: 's',
      hand: HandData(heroCards: 'Ah Ad', position: pos),
      evalResult: EvaluationResult(
        correct: false,
        expectedAction: exp,
        userEquity: 0,
        expectedEquity: 0,
      ),
    );
  }

  test('overfold', () {
    final m = Mistake(
      spot: spot('push'),
      action: PlayerAction.fold,
      handStrength: 0.8,
    );
    expect(engine.categorize(m), 'Overfold');
    expect(m.category, 'Overfold');
  });

  test('overcall', () {
    final m = Mistake(
      spot: spot('fold'),
      action: PlayerAction.call,
      handStrength: 0.2,
    );
    expect(engine.categorize(m), 'Overcall');
  });

  test('wrong push', () {
    final m = Mistake(
      spot: spot('call', pos: HeroPosition.utg),
      action: PlayerAction.push,
      handStrength: 0.5,
    );
    expect(engine.categorize(m), 'Wrong Push');
  });

  test('wrong call', () {
    final m = Mistake(
      spot: spot('push'),
      action: PlayerAction.call,
      handStrength: 0.5,
    );
    expect(engine.categorize(m), 'Wrong Call');
  });

  test('missed value', () {
    final m = Mistake(
      spot: spot('raise'),
      action: PlayerAction.check,
      handStrength: 0.6,
    );
    expect(engine.categorize(m), 'Missed Value');
  });

  test('too passive', () {
    final m = Mistake(
      spot: spot('call'),
      action: PlayerAction.check,
      handStrength: 0.4,
    );
    expect(engine.categorize(m), 'Too Passive');
  });

  test('too aggro', () {
    final m = Mistake(
      spot: spot('check'),
      action: PlayerAction.raise,
      handStrength: 0.5,
    );
    expect(engine.categorize(m), 'Too Aggro');
  });

  test('unclassified', () {
    final m = Mistake(
      spot: spot('push'),
      action: PlayerAction.push,
      handStrength: 0.5,
    );
    expect(engine.categorize(m), 'Unclassified');
  });
}
