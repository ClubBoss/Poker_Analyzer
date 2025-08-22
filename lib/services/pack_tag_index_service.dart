import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

enum TagFilterMode { and, or, exact }

class PackTagIndexService {
  PackTagIndexService();

  Future<int> buildIndex({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    const reader = YamlReader();
    final tagMap = <String, Set<String>>{};
    final packMap = <String, List<String>>{};
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final rel = p.relative(f.path, from: dir.path);
        final tags = <String>{for (final t in tpl.tags) t.trim().toLowerCase()}
          ..removeWhere((e) => e.isEmpty);
        if (tags.isEmpty) continue;
        packMap[rel] = tags.toList();
        for (final t in tags) {
          tagMap.putIfAbsent(t, () => <String>{}).add(rel);
        }
      } catch (_) {}
    }
    final file = File(p.join(dir.path, 'tag_index.json'))
      ..createSync(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'tags': {for (final e in tagMap.entries) e.key: e.value.toList()},
        'packs': packMap,
      }),
      flush: true,
    );
    return packMap.length;
  }

  Future<List<String>> search(
    List<String> tags, {
    TagFilterMode mode = TagFilterMode.and,
    String path = 'training_packs/library',
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$path/tag_index.json');
    if (!file.existsSync()) return [];
    Map<String, dynamic> data;
    try {
      data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return [];
    }
    final tagIndex = <String, Set<String>>{};
    for (final e in (data['tags'] as Map?)?.entries ?? {}) {
      tagIndex[e.key.toString()] = {
        for (final p in e.value as List? ?? []) p.toString(),
      };
    }
    final packIndex = <String, Set<String>>{};
    for (final e in (data['packs'] as Map?)?.entries ?? {}) {
      packIndex[e.key.toString()] = {
        for (final t in e.value as List? ?? []) t.toString(),
      };
    }
    final query = [for (final t in tags) t.trim().toLowerCase()]
      ..removeWhere((e) => e.isEmpty);
    if (query.isEmpty) return [];
    Set<String> result;
    switch (mode) {
      case TagFilterMode.or:
        result = <String>{};
        for (final t in query) {
          result.addAll(tagIndex[t] ?? {});
        }
        break;
      case TagFilterMode.exact:
        result = {
          for (final e in packIndex.entries)
            if (e.value.length == query.length && e.value.containsAll(query))
              e.key,
        };
        break;
      case TagFilterMode.and:
      default:
        result = tagIndex[query.first]?.toSet() ?? {};
        for (final t in query.skip(1)) {
          result = result.intersection(tagIndex[t] ?? {});
        }
        break;
    }
    return result.toList();
  }
}
