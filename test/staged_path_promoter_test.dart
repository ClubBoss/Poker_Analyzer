import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_library.dart';
import 'package:poker_analyzer/services/staged_path_promoter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LearningPathTemplateV2 tpl(String id) =>
      LearningPathTemplateV2(id: id, title: id, description: '');

  test('promoteAll filters by prefix and overwrites', () {
    final staging = LearningPathLibrary.staging;
    final mainLib = LearningPathLibrary.main;
    staging.clear();
    mainLib.clear();

    staging.addAll([
      tpl('theory_path_one'),
      tpl('booster_path_two'),
      tpl('theory_path_three'),
    ]);

    final count = const StagedPathPromoter().promoteAll(prefix: 'theory_path_');

    expect(count, 2);
    expect(mainLib.paths.length, 2);
    expect(mainLib.getById('theory_path_one'), isNotNull);
    expect(mainLib.getById('theory_path_three'), isNotNull);
    expect(mainLib.getById('booster_path_two'), isNull);
  });
}
