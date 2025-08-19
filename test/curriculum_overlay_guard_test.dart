import 'package:test/test.dart';
import 'tooling/curriculum_ids.dart';

void main() {
  test('curriculum overlay guard', () {
    expect(kModulePriority.length <= 5, isTrue);
    expect(
      kModulePriority.keys.every(
        (k) => k.startsWith('core_') || k.startsWith('spr_'),
      ),
      isTrue,
    );
    expect(kModulePriority.keys.every(kCurriculumModuleIds.contains), isTrue);

    final order = logicalOrder();
    expect(order.length, kCurriculumModuleIds.length);
    expect(order.toSet(), kCurriculumModuleIds.toSet());

    final nextId = recommendedNext(const <String>{});
    if (nextId != null) {
      expect(kCurriculumModuleIds, contains(nextId));
      expect(nextId.contains(':'), isFalse);
    }
  });
}
