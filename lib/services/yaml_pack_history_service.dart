import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import 'yaml_pack_formatter_service.dart';

class YamlPackHistoryService {
  const YamlPackHistoryService();

  Future<void> saveSnapshot(TrainingPackTemplateV2 pack, String action) async {
    if (pack.id.trim().isEmpty) return;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'training_packs', 'history'));
    await dir.create(recursive: true);
    final ts = DateFormat('yyyyMMddTHHmmss').format(DateTime.now());
    final name = '${pack.id}_${action}_$ts.yaml';
    final file = File(p.join(dir.path, name));
    final formatted = const YamlPackFormatterService().format(pack);
    final map = const YamlReader().read(formatted);
    await const YamlWriter().write(map, file.path);
  }
}
