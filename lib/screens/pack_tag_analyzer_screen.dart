import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class PackTagAnalyzerScreen extends StatefulWidget {
  const PackTagAnalyzerScreen({super.key});

  @override
  State<PackTagAnalyzerScreen> createState() => _PackTagAnalyzerScreenState();
}

class _TagInfo {
  final String tag;
  final int count;
  final List<String> packs;
  final List<String> dups;
  final List<String> similar;
  const _TagInfo(this.tag, this.count, this.packs, this.dups, this.similar);
}

class _PackTagAnalyzerScreenState extends State<PackTagAnalyzerScreen> {
  bool _loading = true;
  bool _asc = false;
  final List<_TagInfo> _tags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await compute(_analyzeTask, '');
    if (!mounted) return;
    setState(() {
      _tags
        ..clear()
        ..addAll([
          for (final m in res)
            _TagInfo(
              m['tag'] as String,
              m['count'] as int,
              [for (final p in m['packs'] as List) p.toString()],
              [for (final d in (m['dups'] as List?) ?? []) d.toString()],
              [for (final s in (m['sim'] as List?) ?? []) s.toString()],
            )
        ]);
      _sort();
      _loading = false;
    });
  }

  void _sort() {
    _tags.sort(
      (a, b) => _asc ? a.count.compareTo(b.count) : b.count.compareTo(a.count),
    );
  }

  void _toggleSort() {
    setState(() {
      _asc = !_asc;
      _sort();
    });
  }

  Future<void> _showPacks(_TagInfo info) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(info.tag),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: [for (final p in info.packs) Text(p)],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  DataRow _row(_TagInfo info) {
    final highlight =
        info.count == 1 || info.dups.isNotEmpty || info.similar.isNotEmpty;
    return DataRow(
      color: highlight ? WidgetStateProperty.all(AppColors.errorBg) : null,
      onSelectChanged: (_) => _showPacks(info),
      cells: [
        DataCell(Text(info.tag)),
        DataCell(Text('${info.count}')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Tag Analyzer'),
        actions: [
          IconButton(onPressed: _toggleSort, icon: const Icon(Icons.sort)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Tag')),
                  DataColumn(
                    label: const Text('Count'),
                    numeric: true,
                    onSort: (_, __) => _toggleSort(),
                  ),
                ],
                rows: [for (final t in _tags) _row(t)],
              ),
            ),
    );
  }
}

int _levenshtein(String a, String b) {
  final m = a.length;
  final n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) {
    dp[i][0] = i;
  }
  for (var j = 0; j <= n; j++) {
    dp[0][j] = j;
  }
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[i][j] = [
        dp[i - 1][j] + 1,
        dp[i][j - 1] + 1,
        dp[i - 1][j - 1] + cost,
      ].reduce((v, e) => v < e ? v : e);
    }
  }
  return dp[m][n];
}

Future<List<Map<String, dynamic>>> _analyzeTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'training_packs', 'library'));
  final tagMap = <String, Set<String>>{};
  final lowerMap = <String, Set<String>>{};
  if (dir.existsSync()) {
    const reader = YamlReader();
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final map = reader.read(await f.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(map);
        final rel = p.relative(f.path, from: dir.path);
        for (final t in tpl.tags) {
          final tag = t.toString();
          final key = tag.trim();
          if (key.isEmpty) continue;
          tagMap.putIfAbsent(tag, () => <String>{}).add(rel);
          lowerMap.putIfAbsent(key.toLowerCase(), () => <String>{}).add(tag);
        }
      } catch (_) {}
    }
  }
  final items = <Map<String, dynamic>>[];
  final tags = tagMap.keys.toList();
  for (final tag in tags) {
    final packs = tagMap[tag]!.toList();
    final dups = lowerMap[tag.toLowerCase()]!.where((t) => t != tag).toList();
    items.add({
      'tag': tag,
      'count': packs.length,
      'packs': packs,
      if (dups.isNotEmpty) 'dups': dups,
    });
  }
  for (var i = 0; i < tags.length; i++) {
    for (var j = i + 1; j < tags.length; j++) {
      if (_levenshtein(tags[i].toLowerCase(), tags[j].toLowerCase()) < 2) {
        final a = items[i];
        final b = items[j];
        (a['sim'] ??= <String>[]).add(tags[j]);
        (b['sim'] ??= <String>[]).add(tags[i]);
      }
    }
  }
  items.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
  return items;
}
