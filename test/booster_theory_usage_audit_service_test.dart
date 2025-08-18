import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_pack_model.dart';
import 'package:poker_analyzer/models/learning_path_stage_model.dart';
import 'package:poker_analyzer/models/learning_path_template_v2.dart';
import 'package:poker_analyzer/services/booster_theory_usage_audit_service.dart';

LearningPathStageModel _stage({String id = 's1', String? theoryId}) =>
    LearningPathStageModel(
      id: id,
      title: id,
      description: '',
      packId: 'p1',
      requiredAccuracy: 80,
      minHands: 10,
      tags: const ['t'],
      theoryPackId: theoryId,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects unused theory pack', () {
    final packs = [
      TheoryPackModel(id: 't1', title: 'A', sections: const []),
      TheoryPackModel(id: 't2', title: 'B', sections: const []),
    ];
    final paths = [
      LearningPathTemplateV2(
        id: 'path',
        title: 'Path',
        description: '',
        stages: [_stage(theoryId: 't1')],
      ),
    ];
    final issues = const BoosterTheoryUsageAuditService().audit(
      allTheoryPacks: packs,
      allPaths: paths,
    );
    expect(issues.length, 1);
    expect(issues.first.id, 't2');
    expect(issues.first.reason, 'unused');
  });

  test('detects missing theory pack referenced in path', () {
    final packs = [TheoryPackModel(id: 't1', title: 'A', sections: const [])];
    final paths = [
      LearningPathTemplateV2(
        id: 'path',
        title: 'Path',
        description: '',
        stages: [_stage(theoryId: 't2')],
      ),
    ];
    final issues = const BoosterTheoryUsageAuditService().audit(
      allTheoryPacks: packs,
      allPaths: paths,
    );
    expect(issues.length, 1);
    expect(issues.first.id, 't2');
    expect(issues.first.reason, 'missing');
  });
}
