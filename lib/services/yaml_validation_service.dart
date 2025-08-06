import 'dart:io';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlValidationService {
  const YamlValidationService();

  Future<List<(String, String)>> validateAll({String dir = 'assets/packs/v2'}) async {
    final errors = <(String, String)>[];
    final directory = Directory(dir);
    if (!directory.existsSync()) return errors;
    const reader = YamlReader();
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final map = reader.read(await f.readAsString());
        if ((map['meta'] as Map?)?['manualSource'] == true) continue;
        TrainingPackTemplateV2.fromJson(map);
      } catch (e) {
        errors.add((f.path, e.toString()));
      }
    }
    return errors;
  }
}
