import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/skill_tree_node_model.dart';
import 'package:poker_analyzer/services/skill_tree_training_pack_resolver.dart';
import 'package:poker_analyzer/core/training/library/training_pack_library_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await TrainingPackLibraryV2.instance.reload();
  });

  test('returns pack for valid trainingPackId', () async {
    const node = SkillTreeNodeModel(
      id: 'n1',
      title: 'CBet IP',
      category: 'Postflop',
      trainingPackId: 'cbet_ip',
    );

    final resolver = SkillTreeTrainingPackResolver();
    final pack = await resolver.getPackForNode(node);
    expect(pack, isNotNull);
    expect(pack!.id, 'cbet_ip');
  });

  test('returns null when trainingPackId is empty', () async {
    const node = SkillTreeNodeModel(
      id: 'n2',
      title: 'No Pack',
      category: 'Postflop',
    );

    final resolver = SkillTreeTrainingPackResolver();
    final pack = await resolver.getPackForNode(node);
    expect(pack, isNull);
  });
}
