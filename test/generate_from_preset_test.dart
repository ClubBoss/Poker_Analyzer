import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_author_service.dart';
import 'package:poker_analyzer/helpers/training_pack_validator.dart';

void main() {
  group('generateFromPreset', () {
    for (final id in TrainingPackAuthorService.presets.keys) {
      test(id, () {
        final tpl = TrainingPackAuthorService.generateFromPreset(id);
        expect(tpl.spots, isNotEmpty);
        expect(validateTrainingPackTemplate(tpl), isEmpty);
      });
    }
  });
}
