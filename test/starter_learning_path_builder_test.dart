import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/starter_learning_path_builder.dart';
import 'package:poker_analyzer/services/theory_pack_library_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TheoryPackLibraryService.instance.loadAll();
  });

  test('build creates path from starter packs', () {
    final builder = const StarterLearningPathBuilder();
    final path = builder.build();

    expect(path.id, 'starter_path');
    expect(path.title, 'Getting Started');
    expect(path.sections, isNotEmpty);
    expect(path.stages, isNotEmpty);
    expect(path.sections.first.stageIds, hasLength(path.stages.length));
  });
}
