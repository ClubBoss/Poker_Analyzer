import 'dart:io';

import 'package:test/test.dart';
import 'package:poker_analyzer/services/training_pack_library_auto_qa_service.dart';

void main() {
  const validPack = '''
id: dup
title: Pack
spots:
  - id: s1
    hand:
      heroCards: As Ks
      heroIndex: 0
      playerCount: 2
      stacks: {0: 50, 1: 50}
''';

  test('detects duplicate pack ids', () async {
    final dir = await Directory.systemTemp.createTemp();
    await File('${dir.path}/a.yaml').writeAsString(validPack);
    await File('${dir.path}/b.yaml').writeAsString(validPack);

    final service = TrainingPackLibraryAutoQAService();
    final report = await service.validateDirectory(dir.path);

    expect(report.errors['a.yaml']!.join(), contains('Duplicate id'));
    expect(report.errors['b.yaml']!.join(), contains('Duplicate id'));

    await dir.delete(recursive: true);
  });

  test('reports metadata and spot issues', () async {
    const badPack = '''
id: bad
title: Bad Pack
metadata:
  numSpots: 1
  difficulty: insane
  streets: anywhere
  stackSpread:
    min: 50
    max: 40
spots:
  - id: s1
    hand:
      heroIndex: 5
      playerCount: 2
''';
    final dir = await Directory.systemTemp.createTemp();
    await File('${dir.path}/bad.yaml').writeAsString(badPack);

    final service = TrainingPackLibraryAutoQAService();
    final report = await service.validateDirectory(dir.path);
    final errs = report.errors['bad.yaml']!;

    expect(errs.any((e) => e.contains('numSpots=1')), isTrue);
    expect(errs.any((e) => e.contains('Invalid difficulty')), isTrue);
    expect(errs.any((e) => e.contains('Invalid streets')), isTrue);
    expect(errs.any((e) => e.contains('stackSpread')), isTrue);
    expect(errs.any((e) => e.contains('missing hand')), isTrue);
    expect(errs.any((e) => e.contains('heroIndex')), isTrue);

    await dir.delete(recursive: true);
  });
}
