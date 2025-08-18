import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';
import 'yaml_pack_auto_tagger.dart';

class PackLibraryRefactorEngine {
  final YamlReader reader;
  final YamlWriter writer;
  final YamlPackAutoTagger tagger;
  const PackLibraryRefactorEngine({
    YamlReader? yamlReader,
    YamlWriter? yamlWriter,
    YamlPackAutoTagger? autoTagger,
  }) : reader = yamlReader ?? const YamlReader(),
       writer = yamlWriter ?? const YamlWriter(),
       tagger = autoTagger ?? const YamlPackAutoTagger();

  Future<void> refactorAll(String path) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, path));
    if (!dir.existsSync()) return;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final map = reader.read(yaml);
        tpl.name = _norm(tpl.name);
        tpl.goal = _norm(tpl.goal);
        tpl.description = _norm(tpl.description);
        tpl.tags = tagger.generateTags(tpl);
        final pos = <HeroPosition>{
          for (final p in tpl.positions) parseHeroPosition(p),
        }..remove(HeroPosition.unknown);
        final sorted = pos.toList()
          ..sort(
            (a, b) =>
                kPositionOrder.indexOf(a).compareTo(kPositionOrder.indexOf(b)),
          );
        tpl.positions = [for (final p in sorted) p.label];
        await writer.write(_orderedMap(tpl), f.path);
        final safeA = (tpl.audience ?? 'any')
            .replaceAll(' ', '_')
            .toLowerCase();
        final safeT = (tpl.category ?? 'pack')
            .replaceAll(' ', '_')
            .toLowerCase();
        final ts = DateFormat('yyyyMMdd').format(tpl.created);
        final newPath = p.join(f.parent.path, 'lib_${safeA}_${safeT}_$ts.yaml');
        if (p.basename(f.path) != p.basename(newPath)) {
          await File(newPath).writeAsString(await f.readAsString());
          await f.delete();
        }
      } catch (_) {}
    }
  }

  String _norm(String s) {
    final v = s.trim();
    if (v.isEmpty) return '';
    return v[0].toUpperCase() + v.substring(1);
  }

  Map<String, dynamic> _orderedMap(TrainingPackTemplateV2 tpl) {
    final json = tpl.toJson();
    json['title'] = json.remove('name');
    final map = <String, dynamic>{};
    for (final k in ['id', 'title', 'tags', 'meta', 'spots']) {
      if (json.containsKey(k)) map[k] = json.remove(k);
    }
    for (final e in json.entries) {
      map[e.key] = e.value;
    }
    return map;
  }
}
