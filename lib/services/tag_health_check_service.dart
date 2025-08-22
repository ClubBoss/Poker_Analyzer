import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class TagHealthCheckService {
  TagHealthCheckService();

  Future<void> runChecks({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return;
    const reader = YamlReader();
    final counts = <String, int>{};
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        for (final t in tpl.tags) {
          final tag = t.trim().toLowerCase();
          if (tag.isEmpty) continue;
          counts[tag] = (counts[tag] ?? 0) + 1;
        }
        final c = tpl.category?.trim().toLowerCase();
        if (c != null && c.isNotEmpty) {
          counts[c] = (counts[c] ?? 0) + 1;
        }
      } catch (_) {}
    }
    final tags = counts.keys.toList();
    final typos = <List<String>>[];
    for (var i = 0; i < tags.length; i++) {
      for (var j = i + 1; j < tags.length; j++) {
        final a = tags[i];
        final b = tags[j];
        final d = _levenshtein(a, b);
        if (d > 0 && d <= 1) typos.add([a, b]);
      }
    }
    final single = [
      for (final e in counts.entries)
        if (e.value == 1) e.key,
    ];
    final normMap = <String, Set<String>>{};
    for (final t in tags) {
      final n = _normalize(t);
      normMap.putIfAbsent(n, () => <String>{}).add(t);
    }
    final dups = [
      for (final e in normMap.entries)
        if (e.value.length > 1) e.value.toList(),
    ];
    final matrixFile = File('${dir.path}/tag_matrix.yaml');
    final mapped = <String>{};
    if (matrixFile.existsSync()) {
      try {
        final m = reader.read(await matrixFile.readAsString());
        for (final v in m.values) {
          if (v is List) {
            for (final t in v) {
              mapped.add(t.toString().trim().toLowerCase());
            }
          }
        }
      } catch (_) {}
    }
    final unmapped = [
      for (final t in tags)
        if (mapped.isNotEmpty && !mapped.contains(t)) t,
    ];
    final file = File('${dir.path}/tag_health_report.json')
      ..createSync(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'typos': typos,
        'single_use': single,
        'duplicates': dups,
        'unmapped': unmapped,
      }),
      flush: true,
    );
  }

  int _levenshtein(String s, String t) {
    final m = s.length;
    final n = t.length;
    if (m == 0) return n;
    if (n == 0) return m;
    final table = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) {
      table[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      table[0][j] = j;
    }
    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        final del = table[i - 1][j] + 1;
        final ins = table[i][j - 1] + 1;
        final sub = table[i - 1][j - 1] + cost;
        table[i][j] = [del, ins, sub].reduce((a, b) => a < b ? a : b);
      }
    }
    return table[m][n];
  }

  String _normalize(String tag) {
    var res = tag.toLowerCase();
    const map = {
      'zero': '0',
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
    };
    for (final e in map.entries) {
      res = res.replaceAll(e.key, e.value);
    }
    res = res.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return res;
  }
}
