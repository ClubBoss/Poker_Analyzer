import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';

Future<void> main(List<String> args) async {
  final src = args.isNotEmpty ? args[0] : 'assets/packs/v2';
  final out = args.length > 1 ? args[1] : 'assets/packs/v2/library_index.json';
  final dir = Directory(src);
  if (!dir.existsSync()) {
    stderr.writeln('Directory not found: $src');
    exit(1);
  }
  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.yaml'))
      .toList();
  final list = <Map<String, dynamic>>[];
  for (final file in files) {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
      if (tpl.meta['manualSource'] == true) continue;
      list.add({
        'id': tpl.id,
        'name': tpl.name,
        'description': tpl.description,
        if (tpl.goal.isNotEmpty) 'goal': tpl.goal,
        if (tpl.audience != null && tpl.audience!.isNotEmpty)
          'audience': tpl.audience,
        if (tpl.tags.isNotEmpty) 'tags': tpl.tags,
        if (tpl.category != null && tpl.category!.isNotEmpty)
          'mainTag': tpl.category,
        'type': tpl.type.name,
        'gameType': tpl.gameType.name,
        'bb': tpl.bb,
        'spotCount': tpl.spotCount,
        if (tpl.positions.isNotEmpty) 'positions': tpl.positions,
        if (tpl.meta.isNotEmpty) 'meta': tpl.meta,
      });
    } catch (_) {}
  }
  final file = File(out)..createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(list));
  stdout.writeln('Wrote ${list.length} items to ${p.normalize(out)}');
}
