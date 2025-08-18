import 'dart:io';
import 'package:test/test.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

void main() {
  test('manual legacy packs parse', () async {
    final dir = Directory('assets/packs/v2/manual_legacy');
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'));
    for (final f in files) {
      final yaml = await f.readAsString();
      expect(
        () => TrainingPackTemplateV2.fromYamlAuto(yaml),
        returnsNormally,
        reason: f.path,
      );
    }
  });
}
