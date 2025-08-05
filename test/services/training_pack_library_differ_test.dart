import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_library_differ.dart';

void main() {
  const packA = '''
id: a
title: Pack A
spots:
  - id: s1
    hand: {}
''';

  const packA2 = '''
id: a
title: Pack A2
spots:
  - id: s1
    hand: {}
''';

  const packB = '''
id: b
title: Pack B
spots:
  - id: s2
    hand: {}
''';

  const packC = '''
id: c
title: Pack C
spots:
  - id: s3
    hand: {}
''';

  test('detects added, removed, and changed packs', () async {
    final oldDir = await Directory.systemTemp.createTemp();
    final newDir = await Directory.systemTemp.createTemp();
    try {
      await File('${oldDir.path}/a.yaml').writeAsString(packA);
      await File('${oldDir.path}/b.yaml').writeAsString(packB);

      await File('${newDir.path}/a.yaml').writeAsString(packA2);
      await File('${newDir.path}/c.yaml').writeAsString(packC);

      final differ = TrainingPackLibraryDiffer();
      final result = await differ.diff(oldDir.path, newDir.path);

      expect(result.added, ['c']);
      expect(result.removed, ['b']);
      expect(result.changed, ['a']);
    } finally {
      await oldDir.delete(recursive: true);
      await newDir.delete(recursive: true);
    }
  });
}
