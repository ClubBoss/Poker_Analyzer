import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/booster_quick_tester_engine.dart';
import '../services/booster_pack_validator_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class BoosterBulkStatsDashboard extends StatefulWidget {
  const BoosterBulkStatsDashboard({super.key});

  @override
  State<BoosterBulkStatsDashboard> createState() =>
      _BoosterBulkStatsDashboardState();
}

class _BoosterBulkStatsDashboardState extends State<BoosterBulkStatsDashboard> {
  bool _loading = true;
  int _total = 0;
  int _valid = 0;
  double _evAvg = 0;
  int _duplicates = 0;
  int _empty = 0;
  final List<(String, String)> _quality = [];
  final List<(String, int)> _tags = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await compute(_statsTask, 'yaml_out/boosters');
    if (!mounted) return;
    setState(() {
      _loading = false;
      _total = res['total'] as int? ?? 0;
      _valid = res['valid'] as int? ?? 0;
      _evAvg = (res['ev'] as num?)?.toDouble() ?? 0;
      _duplicates = res['dupes'] as int? ?? 0;
      _empty = res['empty'] as int? ?? 0;
      _quality
        ..clear()
        ..addAll([
          for (final q in res['packs'] as List) (q[0] as String, q[1] as String)
        ]);
      _tags
        ..clear()
        ..addAll([
          for (final t in res['tags'] as List)
            (t[0] as String, (t[1] as num).toInt())
        ]);
    });
  }

  DataTable _qualityTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Pack')),
        DataColumn(label: Text('Quality')),
      ],
      rows: [
        for (final q in _quality)
          DataRow(
            color: q.$2 == 'fail'
                ? WidgetStateProperty.all(AppColors.errorBg)
                : q.$2 == 'warning'
                    ? WidgetStateProperty.all(
                        Colors.orange.withValues(alpha: .2))
                    : null,
            cells: [DataCell(Text(q.$1)), DataCell(Text(q.$2))],
          ),
      ],
    );
  }

  DataTable _tagTable() {
    return DataTable(
      columns: const [
        DataColumn(label: Text('Tag')),
        DataColumn(label: Text('Count')),
      ],
      rows: [
        for (final t in _tags)
          DataRow(cells: [DataCell(Text(t.$1)), DataCell(Text('${t.$2}'))]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booster Bulk Stats'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total packs: $_total'),
                        const SizedBox(height: 4),
                        Text(
                            'Valid: $_valid (${_total == 0 ? 0 : (_valid * 100 / _total).toStringAsFixed(1)}%)'),
                        const SizedBox(height: 4),
                        Text('Invalid: ${_total - _valid}'),
                        const SizedBox(height: 4),
                        Text('Average EV: ${_evAvg.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        Text('Duplicates: $_duplicates'),
                        const SizedBox(height: 4),
                        Text('Empty explanations: $_empty'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _tagTable(),
                const SizedBox(height: 16),
                _qualityTable(),
              ],
            ),
    );
  }
}

Future<Map<String, dynamic>> _statsTask(String dir) async {
  final directory = Directory(dir);
  if (!directory.existsSync()) return <String, dynamic>{};
  const engine = BoosterQuickTesterEngine();
  const validator = BoosterPackValidatorService();
  int total = 0;
  int valid = 0;
  double evSum = 0;
  int evCount = 0;
  int duplicates = 0;
  int empty = 0;
  final tags = <String, int>{};
  final packs = <List<String>>[];

  final files = directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.yaml'));
  for (final file in files) {
    try {
      final yaml = await file.readAsString();
      final tpl = TrainingPackTemplateV2.fromYamlString(yaml);
      final report = engine.test(tpl);
      total++;
      final validation = validator.validate(tpl);
      if (validation.isValid) {
        valid++;
      }
      evSum += report.evAvg * report.totalSpots;
      evCount += report.totalSpots;
      empty += report.emptyExplanations;
      duplicates +=
          report.issues.where((i) => i.startsWith('duplicate_id')).length;
      if (report.issues.contains('duplicate_ids')) {
        if (!report.issues.any((i) => i.startsWith('duplicate_id'))) {
          duplicates++;
        }
      }
      for (final e in report.tagHistogram.entries) {
        tags[e.key] = (tags[e.key] ?? 0) + e.value;
      }
      final name = tpl.name.isNotEmpty
          ? tpl.name
          : file.path.split(Platform.pathSeparator).last;
      packs.add([name, report.quality]);
    } catch (_) {}
  }
  final tagList = tags.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topTags = [
    for (final e in tagList.take(10)) [e.key, e.value]
  ];
  return {
    'total': total,
    'valid': valid,
    'dupes': duplicates,
    'empty': empty,
    if (evCount > 0) 'ev': evSum / evCount,
    'tags': topTags,
    'packs': packs,
  };
}
