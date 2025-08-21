import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/engine/training_type_engine.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class PackCoverageStatsScreen extends StatefulWidget {
  const PackCoverageStatsScreen({super.key});

  @override
  State<PackCoverageStatsScreen> createState() =>
      _PackCoverageStatsScreenState();
}

class _PackCoverageStatsScreenState extends State<PackCoverageStatsScreen> {
  bool _loading = true;
  String _filter = 'all';
  final Map<String, int> _pos = {};
  final Map<String, int> _stack = {};
  final Map<String, int> _type = {};
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await compute(_statsTask, _filter);
    if (!mounted) return;
    setState(() {
      _pos
        ..clear()
        ..addAll((res['pos'] as Map).cast<String, int>());
      _stack
        ..clear()
        ..addAll((res['stack'] as Map).cast<String, int>());
      _type
        ..clear()
        ..addAll((res['type'] as Map).cast<String, int>());
      _total = res['total'] as int? ?? 0;
      _loading = false;
    });
  }

  DataTable _table(String title, Map<String, int> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return DataTable(
      columns: [
        DataColumn(label: Text(title)),
        const DataColumn(label: Text('%'), numeric: true),
        const DataColumn(label: Text('n'), numeric: true),
      ],
      rows: [
        for (final e in entries)
          DataRow(
            color: e.value == 0
                ? WidgetStateProperty.all(AppColors.errorBg)
                : null,
            cells: [
              DataCell(Text(e.key)),
              DataCell(
                Text(
                  _total == 0
                      ? '0%'
                      : '${(e.value * 100 / _total).toStringAsFixed(1)}%',
                ),
              ),
              DataCell(Text('${e.value}')),
            ],
          ),
      ],
    );
  }

  Widget _filterButtons() {
    Widget btn(String id, String label) => TextButton(
      onPressed: () {
        setState(() => _filter = id);
        _load();
      },
      child: Text(
        label,
        style: TextStyle(color: _filter == id ? Colors.amber : Colors.white),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        btn('base', 'Base'),
        btn('archive', 'Archive'),
        btn('all', 'All'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Coverage Stats'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _filterButtons(),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _table('Position', _pos),
                const SizedBox(height: 24),
                _table('Stack', _stack),
                const SizedBox(height: 24),
                _table('Type', _type),
                const SizedBox(height: 24),
                Text('Total spots: $_total'),
              ],
            ),
    );
  }
}

Future<Map<String, dynamic>> _statsTask(String filter) async {
  final docs = await getApplicationDocumentsDirectory();
  const reader = YamlReader();
  final pos = <String, int>{};
  final stack = <String, int>{};
  final type = <String, int>{};
  int total = 0;

  Future<void> handle(File f) async {
    try {
      final map = reader.read(await f.readAsString());
      final tpl = TrainingPackTemplateV2.fromJson(map);
      final c = tpl.spots.length;
      type[tpl.trainingType.name] = (type[tpl.trainingType.name] ?? 0) + c;
      for (final s in tpl.spots) {
        total++;
        final p = s.hand.position.name.toUpperCase();
        pos[p] = (pos[p] ?? 0) + 1;
        final v = s.hand.stacks['${s.hand.heroIndex}'] ?? 0;
        final bb = v.toDouble();
        final r = bb >= 21
            ? '21+'
            : bb >= 13
            ? '13-20'
            : bb >= 8
            ? '8-12'
            : bb >= 5
            ? '5-7'
            : '<5';
        if (r != '<5') stack[r] = (stack[r] ?? 0) + 1;
      }
    } catch (_) {}
  }

  if (filter != 'archive') {
    final dir = Directory(p.join(docs.path, 'training_packs', 'library'));
    if (dir.existsSync()) {
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((e) => e.path.toLowerCase().endsWith('.yaml'));
      for (final f in files) {
        await handle(f);
      }
    }
  }
  if (filter != 'base') {
    final root = Directory(p.join(docs.path, 'training_packs', 'archive'));
    if (root.existsSync()) {
      for (final dir in root.listSync()) {
        if (dir is Directory) {
          for (final f in dir.listSync()) {
            if (f is File && f.path.endsWith('.bak.yaml')) {
              await handle(f);
            }
          }
        }
      }
    }
  }

  for (final p in ['BTN', 'SB', 'BB', 'CO', 'MP', 'UTG']) {
    pos[p] = pos[p] ?? 0;
  }
  for (final r in ['5-7', '8-12', '13-20', '21+']) {
    stack[r] = stack[r] ?? 0;
  }
  for (final t in TrainingType.values) {
    type[t.name] = type[t.name] ?? 0;
  }

  return {'pos': pos, 'stack': stack, 'type': type, 'total': total};
}
