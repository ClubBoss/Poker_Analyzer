import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/matrix_tag_config_service.dart';
import '../theme/app_colors.dart';
import '../core/training/engine/training_type_engine.dart';

class TagMatrixCoverageScreen extends StatefulWidget {
  const TagMatrixCoverageScreen({super.key});

  @override
  State<TagMatrixCoverageScreen> createState() => _TagMatrixCoverageScreenState();
}

class _CellData {
  int count;
  final List<String> packs;
  _CellData(this.count, this.packs);
}

class _TagMatrixCoverageScreenState extends State<TagMatrixCoverageScreen> {
  bool _loading = true;
  TrainingType? _type;
  bool _starter = false;
  final List<MatrixAxis> _axes = [];
  final Map<String, Map<String, _CellData>> _data = {};
  int _max = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await compute(_coverageTask, {
      'type': _type?.name,
      'starter': _starter,
    });
    if (!mounted) return;
    _axes
      ..clear()
      ..addAll([
        for (final a in res['axes'] as List)
          MatrixAxis.fromJson(Map<String, dynamic>.from(a))
      ]);
    _data.clear();
    _max = 1;
    final cells = res['cells'] as Map;
    cells.forEach((k, v) {
      final inner = <String, _CellData>{};
      (v as Map).forEach((kk, vv) {
        final m = vv as Map;
        final d = _CellData(m['count'] as int, [for (final p in m['packs']) p.toString()]);
        if (d.count > _max) _max = d.count;
        inner[kk as String] = d;
      });
      _data[k as String] = inner;
    });
    if (_max <= 0) _max = 1;
    setState(() => _loading = false);
  }

  Color _color(int n) {
    if (n == 0) return Colors.black26;
    if (n == 1) return Colors.orange.withOpacity(.4);
    final t = n / _max;
    return Color.lerp(Colors.blueGrey.shade300, Colors.greenAccent, t)!;
  }

  Future<void> _show(String x, String y) async {
    final list = _data[x]?[y]?.packs ?? [];
    if (list.isEmpty) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('$x · $y'),
        content: SizedBox(
          width: 300,
          child: ListView(shrinkWrap: true, children: [for (final p in list) Text(p)]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  DataRow _row(String x) {
    final yVals = _axes[1].values;
    return DataRow(cells: [
      DataCell(Text(x)),
      ...[
        for (final y in yVals)
          DataCell(GestureDetector(
            onTap: () => _show(x, y),
            child: Container(
              color: _color(_data[x]?[y]?.count ?? 0),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Text('${_data[x]?[y]?.count ?? 0}'),
            ),
          )),
      ]
    ]);
  }

  Widget _table() {
    if (_axes.length < 2) return const SizedBox.shrink();
    final xVals = _axes[0].values;
    final yVals = _axes[1].values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text(_axes[0].name)),
          ...[for (final y in yVals) DataColumn(label: Text(y))]
        ],
        rows: [for (final x in xVals) _row(x)],
      ),
    );
  }

  Widget _filters() {
    return Row(children: [
      DropdownButton<TrainingType?>(
        value: _type,
        hint: const Text('All'),
        onChanged: (v) {
          setState(() => _type = v);
          _load();
        },
        items: [
          const DropdownMenuItem(value: null, child: Text('All')),
          ...[
            for (final t in TrainingType.values)
              DropdownMenuItem(value: t, child: Text(t.name))
          ]
        ],
      ),
      const SizedBox(width: 16),
      Row(children: [
        Checkbox(
          value: _starter,
          onChanged: (v) {
            setState(() => _starter = v ?? false);
            _load();
          },
        ),
        const Text('starter'),
      ])
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Matrix Coverage'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(48), child: _filters()),
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [_table()]),
    );
  }
}

Future<Map<String, dynamic>> _coverageTask(Map args) async {
  final axes = await const MatrixTagConfigService().load();
  final xVals = axes[0].values;
  final yVals = axes.length > 1 ? axes[1].values : <String>[];
  final cells = <String, Map<String, Map<String, dynamic>>>{};
  for (final x in xVals) {
    cells[x] = {for (final y in yVals) y: {'count': 0, 'packs': <String>[]}};
  }
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/training_packs/library');
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
        final type = args['type'] as String?;
        if (type != null && type.isNotEmpty && tpl.trainingType.name != type) continue;
        if (args['starter'] == true &&
            !tpl.tags.any((t) => t.toLowerCase().contains('starter'))) {
          continue;
        }
        final rel = p.relative(f.path, from: dir.path);
        final bb = tpl.bb;
        final stack = bb >= 21
            ? '21+'
            : bb >= 13
                ? '13-20'
                : bb >= 8
                    ? '8-12'
                    : bb >= 5
                        ? '5-7'
                        : '<5';
        final posList = tpl.positions.isNotEmpty
            ? tpl.positions
            : [
                for (final t in tpl.tags)
                  if (t.startsWith('position:')) t.substring(9)
              ];
        for (final p0 in posList) {
          final p1 = p0.toUpperCase();
          final map = cells[p1];
          if (map == null) continue;
          final cell = map[stack];
          if (cell == null) continue;
          cell['count'] = (cell['count'] as int) + 1;
          (cell['packs'] as List).add(rel);
        }
      } catch (_) {}
    }
  }
  return {
    'axes': [for (final a in axes) a.toJson()],
    'cells': cells,
  };
}
