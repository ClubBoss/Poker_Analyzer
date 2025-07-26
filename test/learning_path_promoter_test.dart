import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/learning_path_library.dart';
import 'package:poker_analyzer/services/learning_path_promoter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  LearningPathTemplateV2 tpl(String id) => LearningPathTemplateV2(
        id: id,
        title: id,
        description: '',
      );

  test('promoteStaged overwrites matching ids only', () {
    final staging = LearningPathLibrary.staging;
    final target = LearningPathLibrary.main;
    staging.clear();
    target.clear();

    staging.addAll([tpl('path_one'), tpl('path_two')]);
    target.addAll([tpl('path_one'), tpl('path_three')]);

    final count = const LearningPathPromoter().promoteStaged(
      staged: staging,
      target: target,
    );

    expect(count, 1);
    expect(target.paths.length, 2);
    expect(target.getById('path_one'), isNotNull);
    expect(target.getById('path_two'), isNull);
    expect(target.getById('path_three'), isNotNull);
    expect(identical(LearningPathLibrary.main, target), isTrue);
  });
});
