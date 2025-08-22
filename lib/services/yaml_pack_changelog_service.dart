import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlPackChangelogService {
  YamlPackChangelogService();

  Future<void> appendChangeLog(
    TrainingPackTemplateV2 pack,
    String reason,
  ) async {
    if (pack.id.trim().isEmpty) return;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'training_packs', 'history'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${pack.id}_changelog.md'));
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final version = pack.meta['schemaVersion'] ?? '2.0.0';
    await file.writeAsString(
      '- [$date] $reason (v$version)\n',
      mode: FileMode.append,
    );
  }

  Future<String?> loadChangeLog(String packId) async {
    if (packId.trim().isEmpty) return null;
    final docs = await getApplicationDocumentsDirectory();
    final file = File(
      p.join(docs.path, 'training_packs', 'history', '${packId}_changelog.md'),
    );
    if (!await file.exists()) return null;
    return file.readAsString();
  }
}
