import 'dart:io';

import '../../../models/v2/training_pack_template_v2.dart';
import '../../../services/theory_yaml_safe_writer.dart';

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
    String? prevHash;
    if (await file.exists()) {
      prevHash = TheoryYamlSafeWriter.extractHash(await file.readAsString());
    }
    await TheoryYamlSafeWriter().write(
      path: file.path,
      yaml: exportYaml(pack),
      schema: 'TemplateSet',
      prevHash: prevHash,
    );
    return file;
  }
}
