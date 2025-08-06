import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  final lib = TrainingPackLibraryV2.instance;
  setUp(() => lib.clear());
  tearDown(() => lib.clear());

  test('filterBy matches themes', () {
    lib.addPack(
      TrainingPackTemplateV2(
        id: 'a',
        name: 'A',
        trainingType: TrainingType.pushFold,
        meta: {'theme': 'pushfold'},
      ),
    );
    lib.addPack(
      TrainingPackTemplateV2(
        id: 'b',
        name: 'B',
        trainingType: TrainingType.pushFold,
        meta: {
          'theme': ['3bet', 'icm']
        },
      ),
    );
    lib.addPack(
      TrainingPackTemplateV2(
        id: 'c',
        name: 'C',
        trainingType: TrainingType.pushFold,
      ),
    );

    final res = lib.filterBy(themes: ['ICM']);
    expect(res.map((e) => e.id).toList(), ['b']);
  });
}
