import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'yaml_pack_markdown_preview_service.dart';

class YamlPackExporterService {
  const YamlPackExporterService();

  Future<File> exportToTextFile(dynamic pack, [String format = 'yaml']) async {
    final TrainingPackTemplateV2 tpl;
    if (pack is TrainingPackTemplateV2) {
      tpl = pack;
    } else if (pack is File) {
      final yaml = await pack.readAsString();
      tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
    } else {
      throw ArgumentError('pack');
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'training_packs', 'exports'));
    await dir.create(recursive: true);

    final fmt = format.toLowerCase();
    final file = File(p.join(dir.path, '${tpl.id}_$fmt.txt'));

    if (fmt == 'markdown') {
      final md =
          const YamlPackMarkdownPreviewService().generateMarkdownPreview(tpl) ??
              '';
      await file.writeAsString(md);
    } else {
      await const YamlWriter().write(tpl.toJson(), file.path);
    }

    return file;
  }
}
