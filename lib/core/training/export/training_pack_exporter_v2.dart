import 'dart:io';

import '../../../models/v2/training_pack_template_v2.dart';

class TrainingPackExporterV2 {
  const TrainingPackExporterV2();

  String exportYaml(TrainingPackTemplateV2 pack) => pack.toYamlString();

  Future<File> exportToFile(
    TrainingPackTemplateV2 pack, {
    String? fileName,
  }) async {
    final generatedDir = Directory('packs/generated');
    final exportedDir = Directory('packs/exported');
    final dir = await generatedDir.exists() ? generatedDir : exportedDir;
    await dir.create(recursive: true);
    final safeName = (fileName ?? pack.name)
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final file = File('${dir.path}/$safeName.yaml');
    await file.writeAsString(exportYaml(pack));
    return file;
  }
}
