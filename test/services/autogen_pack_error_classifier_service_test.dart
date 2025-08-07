import 'package:test/test.dart';
import 'package:poker_analyzer/services/autogen_pack_error_classifier_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/models/game_type.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

TrainingPackTemplateV2 _emptyPack() => TrainingPackTemplateV2(
      id: 'id',
      name: 'name',
      trainingType: TrainingType.custom,
      spots: [],
      spotCount: 0,
      tags: [],
      gameType: GameType.cash,
      bb: 0,
      positions: [],
      meta: {},
    );

void main() {
  group('AutogenPackErrorClassifierService', () {
    const classifier = AutogenPackErrorClassifierService();

    setUp(() => AutogenPackErrorClassifierService.clearRecentErrors());

    test('detects no spots generated', () {
      final type = classifier.classify(_emptyPack(), null);
      expect(type, AutogenPackErrorType.noSpotsGenerated);
    });

    test('detects duplicate error', () {
      final type =
          classifier.classify(_emptyPack(), Exception('duplicate spot'));
      expect(type, AutogenPackErrorType.duplicate);
    });

    test('detects invalid board', () {
      final type = classifier.classify(
        _emptyPack(),
        Exception('Invalid board sequence'),
      );
      expect(type, AutogenPackErrorType.invalidBoard);
    });

    test('stores recent errors with classification', () {
      classifier.classify(_emptyPack(), Exception('duplicate spot'));
      final errors = AutogenPackErrorClassifierService.getRecentErrors();
      expect(errors, hasLength(1));
      expect(errors.first.type, AutogenPackErrorType.duplicate);
    });

    test('limits recent errors to 50', () {
      for (var i = 0; i < 60; i++) {
        classifier.classify(_emptyPack(), Exception('duplicate spot $i'));
      }
      final errors = AutogenPackErrorClassifierService.getRecentErrors();
      expect(errors.length, 50);
    });
  });
}
