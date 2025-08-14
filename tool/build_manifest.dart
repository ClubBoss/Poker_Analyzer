import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/v2/training_pack_template.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
        'Usage: dart run tool/build_manifest.dart <bundlesDir> [outputPath]');
    exit(1);
  }
  final dir = Directory(args[0]);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: ${args[0]}');
    exit(1);
  }
  final outPath = args.length > 1 ? args[1] : p.join(dir.path, 'manifest.json');
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.pka'))
      .toList();
  stdout.writeln('Building manifest for ${files.length} bundles...');
  final items = <Map<String, dynamic>>[];
  for (final file in files) {
    try {
      final bytes = file.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      final tplFile =
          archive.files.firstWhere((e) => e.name == 'template.json');
      final jsonMap =
          jsonDecode(utf8.decode(tplFile.content)) as Map<String, dynamic>;
      final tpl = TrainingPackTemplate.fromJson(jsonMap);
      final pngName = '${tpl.id}.png';
      final pngFile = File(p.join(file.parent.path, pngName));
      final hasPng = pngFile.existsSync();
      items.add({
        'id': tpl.id,
        'name': tpl.name,
        'description': tpl.description,
        'spots': tpl.spots.length,
        'evCovered': tpl.evCovered,
        'icmCovered': tpl.icmCovered,
        'createdAt': tpl.createdAt.toIso8601String(),
        'lastGenerated': tpl.lastGeneratedAt?.toIso8601String(),
        if (hasPng) 'png': pngName,
        'pka': p.basename(file.path),
      });
      stdout.writeln(
          '[OK] ${p.basename(file.path)}${hasPng ? '' : ' (preview missing)'}');
    } catch (_) {
      stdout.writeln('[ERROR] ${p.basename(file.path)}');
    }
  }
  items.sort((a, b) {
    final sa = a['lastGenerated'] as String?;
    final sb = b['lastGenerated'] as String?;
    final da = sa != null && sa.isNotEmpty
        ? DateTime.tryParse(sa) ?? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);
    final db = sb != null && sb.isNotEmpty
        ? DateTime.tryParse(sb) ?? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.fromMillisecondsSinceEpoch(0);
    return db.compareTo(da);
  });
  final outFile = File(outPath)..createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(items));
  final size = (outFile.lengthSync() / 1024).toStringAsFixed(1);
  stdout.writeln(
      'Saved ${p.basename(outFile.path)}  (${items.length} items, $size KB)');
}
