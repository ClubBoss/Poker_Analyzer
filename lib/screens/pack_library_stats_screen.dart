import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class PackLibraryStatsScreen extends StatefulWidget {
  const PackLibraryStatsScreen({super.key});
  @override
  State<PackLibraryStatsScreen> createState() => _PackLibraryStatsScreenState();
}

class _PackLibraryStatsScreenState extends State<PackLibraryStatsScreen> {
  bool _loading = true;
  int _total = 0;
  final Map<String, int> _audience = {};
  final List<(String, int)> _tags = [];
  double? _ev;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await compute(_statsTask, '');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _total = res['total'] as int? ?? 0;
      _audience
        ..clear()
        ..addAll((res['audience'] as Map).cast<String, int>());
      _tags
        ..clear()
        ..addAll([
          for (final e in res['tags'] as List)
            (e[0] as String, (e[1] as num).toInt()),
        ]);
      _ev = (res['ev'] as num?)?.toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Статистика библиотеки')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('🔄 Обновить'),
                ),
                const SizedBox(height: 16),
                Text('Всего паков: $_total'),
                const SizedBox(height: 12),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Audience')),
                    DataColumn(label: Text('Count')),
                  ],
                  rows: [
                    for (final e in _audience.entries)
                      DataRow(
                        cells: [
                          DataCell(Text(e.key)),
                          DataCell(Text('${e.value}')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                DataTable(
                  columns: const [
                    DataColumn(label: Text('Tag')),
                    DataColumn(label: Text('Count')),
                  ],
                  rows: [
                    for (final t in _tags)
                      DataRow(
                        cells: [
                          DataCell(Text(t.$1)),
                          DataCell(Text('${t.$2}')),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_ev != null)
                  Text('Средний EV/ICM: ${_ev!.toStringAsFixed(2)}'),
              ],
            ),
    );
  }
}

Future<Map<String, dynamic>> _statsTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/training_packs/library');
  const reader = YamlReader();
  int total = 0;
  final aud = <String, int>{};
  final tags = <String, int>{};
  double evSum = 0;
  int evCount = 0;
  if (dir.existsSync()) {
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final map = reader.read(await f.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(map);
        total++;
        final a = tpl.audience ?? 'Unknown';
        aud[a] = (aud[a] ?? 0) + 1;
        for (final t in tpl.tags) {
          tags[t] = (tags[t] ?? 0) + 1;
        }
        final ev = (map['evScore'] as num?)?.toDouble() ??
            (tpl.meta['evScore'] as num?)?.toDouble();
        if (ev != null) {
          evSum += ev;
          evCount++;
        }
      } catch (_) {}
    }
  }
  final tagList = tags.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topTags = [
    for (final e in tagList.take(10)) [e.key, e.value],
  ];
  return {
    'total': total,
    'audience': aud,
    'tags': topTags,
    if (evCount > 0) 'ev': evSum / evCount,
  };
}
