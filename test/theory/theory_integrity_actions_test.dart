import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:poker_analyzer/recall/theory_map.dart';

void main() {
  test('action tags resolve to theory ids with overview fallback', () {
    const yaml = '''
- tags: [open_fold, position:EP]
- tags: [open_fold, position:EP]
- tags: [open_fold, position:EP]
- tags: [open_fold, position:EP]
- tags: [open_fold, position:EP]
- tags: [open_fold, position:EP]
- tags: [open_fold, position:MP]
- tags: [open_fold, position:CO]
- tags: [open_fold, position:BTN]
- tags: [open_fold, position:SB]
- tags: [open_fold]
- tags: [3bet_push, stack:10-15]
- tags: [3bet_push, stack:10-15]
- tags: [3bet_push, stack:10-15]
- tags: [3bet_push, stack:10-15]
- tags: [3bet_push, stack:10-15]
- tags: [3bet_push, stack:10-15]
- tags: [3bet_push, stack:15-20]
- tags: [3bet_push, stack:20-25]
- tags: [3bet_push, stack:25-30]
''';

    final entries = loadYaml(yaml) as YamlList;
    var mapped = 0;
    var total = 0;
    for (final e in entries) {
      final tags = (e['tags'] as YamlList).cast<String>();
      final id = TheoryMap.idFor(tags);
      expect(id, isNotNull);
      if (id == 'open_fold_overview' || id == '3bp_overview') {
        // overview fallback
      } else {
        mapped++;
      }
      total++;
    }
    expect(mapped / total, greaterThanOrEqualTo(0.95));
    // ensure explicit fallback works for 3bet push
    expect(TheoryMap.idFor(['3bet_push']), '3bp_overview');
  });
}
