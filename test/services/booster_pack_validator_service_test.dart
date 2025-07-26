import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_pack_validator_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';
import 'package:poker_analyzer/models/v2/game_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('validator detects issues', () {
    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(heroCards: '', position: HeroPosition.unknown),
    );
    final pack = TrainingPackTemplateV2(
      id: '',
      name: 'Pack',
      trainingType: TrainingType.pushFold,
      gameType: GameType.tournament,
      spots: [spot],
      spotCount: 1,
      positions: const [],
      meta: const {'type': 'booster'},
    );

    final report = const BoosterPackValidatorService().validate(pack);
    expect(report.isValid, isFalse);
    expect(report.errors, contains('missing_pack_id'));
    expect(report.errors, contains('empty_heroCards:s1'));
  });
}
