import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../services/training_pack_storage_service.dart';
import '../models/training_pack_stats.dart';
import 'training_pack_review_screen.dart';

class TrainingPackComparisonScreen extends StatefulWidget {
  const TrainingPackComparisonScreen({super.key});

  @override
  State<TrainingPackComparisonScreen> createState() => _TrainingPackComparisonScreenState();
}

class _PackDataSource extends DataTableSource {
  final List<TrainingPackStats> stats;
  final void Function(TrainingPackStats) onOpen;
  final double maxAccuracy;
  final double minAccuracy;
  final DateTime now;

  _PackDataSource({
    required this.stats,
    required this.onOpen,
    required this.maxAccuracy,
    required this.minAccuracy,
    required this.now,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= stats.length) return null;
    final s = stats[index];
    final isBest = s.accuracy == maxAccuracy;
    final isWorst = s.accuracy == minAccuracy;
    final forgotten =
        s.lastSession == null || now.difference(s.lastSession!).inDays >= 7;
    final color = isBest
        ? Colors.greenAccent
        : isWorst
            ? Colors.redAccent
            : null;
    return DataRow(
      color: forgotten
          ? MaterialStateProperty.all(Colors.grey.shade800)
          : null,
      onSelectChanged: (_) => onOpen(s),
      cells: [
        DataCell(Tooltip(message: 'Открыть обзор пака', child: Text(s.pack.name))),
        DataCell(Text(s.total.toString())),
        DataCell(
          Tooltip(
            message: '${s.total - s.mistakes} из ${s.total} верно',
            child: Text(
              '${s.accuracy.toStringAsFixed(1).padLeft(5)}%',
              style: TextStyle(color: color),
            ),
          ),
        ),
        DataCell(Text(s.mistakes.toString())),
        DataCell(Text(s.rating.toStringAsFixed(1).padLeft(4))),
        DataCell(Tooltip(
          message: s.lastSession != null
              ? 'Последняя сессия: '
                  '${DateFormat('d MMMM yyyy', 'ru').format(s.lastSession!)}'
              : 'Нет данных',
          child: Text(s.lastSession != null
              ? DateFormat('dd.MM').format(s.lastSession!)
              : '-'),
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => stats.length;

  @override
  int get selectedRowCount => 0;
}


class _TrainingPackComparisonScreenState extends State<TrainingPackComparisonScreen> {
  int _sortColumn = 0;
  bool _ascending = true;
  bool _forgottenOnly = false;

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  List<TrainingPackStats> _sortedStats(List<TrainingPack> packs) {
    final stats = [for (final p in packs) TrainingPackStats.fromPack(p)];
    stats.sort((a, b) {
      int cmp;
      switch (_sortColumn) {
        case 0:
          cmp = a.pack.name.compareTo(b.pack.name);
          break;
        case 1:
          cmp = a.total.compareTo(b.total);
          break;
        case 2:
          cmp = a.accuracy.compareTo(b.accuracy);
          break;
        case 3:
          cmp = a.mistakes.compareTo(b.mistakes);
          break;
        case 4:
          cmp = a.rating.compareTo(b.rating);
          break;
        case 5:
          cmp = (a.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(b.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0));
          break;
        default:
          cmp = 0;
      }
      return _ascending ? cmp : -cmp;
    });
    return stats;
  }

  Future<void> _exportCsv() async {
    final packs = context.read<TrainingPackStorageService>().packs;
    final stats = _sortedStats(packs);
    if (stats.isEmpty) return;
    final rows = <List<dynamic>>[];
    rows.add(['Название', 'Рук', 'Точность', 'Ошибки', 'Рейтинг', 'Последняя сессия']);
    var sumTotal = 0;
    var sumMistakes = 0;
    var sumAcc = 0.0;
    var sumRating = 0.0;
    for (final s in stats) {
      rows.add([
        s.pack.name,
        s.total,
        '${s.accuracy.toStringAsFixed(1)}%',
        s.mistakes,
        s.rating.toStringAsFixed(1),
        s.lastSession != null ? DateFormat('dd.MM').format(s.lastSession!) : '-',
      ]);
      sumTotal += s.total;
      sumMistakes += s.mistakes;
      sumAcc += s.accuracy;
      sumRating += s.rating;
    }
    final avgAcc = stats.isNotEmpty ? sumAcc / stats.length : 0.0;
    final avgRating = stats.isNotEmpty ? sumRating / stats.length : 0.0;
    rows.add([
      'Σ',
      sumTotal,
      '${avgAcc.toStringAsFixed(1)}%',
      sumMistakes,
      avgRating.toStringAsFixed(1),
      '-',
    ]);
    assert(rows.every((r) => r.length == rows.first.length));
    final csvStr =
        '\uFEFF${const ListToCsvConverter(fieldDelimiter: ';').convert(rows, eol: '\r\n')}';
    final dir = await getTemporaryDirectory();
    final name =
        'pack_comparison_${DateFormat("yyyy-MM-dd_HH-mm").format(DateTime.now())}.csv';
    final file = File('${dir.path}/$name');
    await file.writeAsString(csvStr, encoding: utf8);
    try {
      await Share.shareXFiles([XFile(file.path)], text: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV экспортирован')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта CSV')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;
    final now = DateTime.now();
    final filtered = _forgottenOnly
        ? [
            for (final p in packs)
              if (p.history.isEmpty ||
                  now.difference(p.history.last.date).inDays >= 7)
                p
          ]
        : packs;
    final stats = _sortedStats(filtered);
    final maxAccuracy = stats.isNotEmpty
        ? stats.map((s) => s.accuracy).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minAccuracy = stats.isNotEmpty
        ? stats.map((s) => s.accuracy).reduce((a, b) => a < b ? a : b)
        : 0.0;

    final source = _PackDataSource(
      stats: stats,
      onOpen: (s) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrainingPackReviewScreen(pack: s.pack),
          ),
        );
      },
      maxAccuracy: maxAccuracy,
      minAccuracy: minAccuracy,
      now: now,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сравнение паков'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportCsv,
        child: const Icon(Icons.share),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Давно не повторял'),
            value: _forgottenOnly,
            onChanged: (v) => setState(() => _forgottenOnly = v),
            activeColor: Colors.orange,
          ),
          Expanded(
            child: PaginatedDataTable(
              sortColumnIndex: _sortColumn,
              sortAscending: _ascending,
              rowsPerPage: 10,
              columns: [
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Название'),
                      if (_sortColumn == 0)
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                    ],
                  ),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Рук'),
                      if (_sortColumn == 1)
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                    ],
                  ),
                  numeric: true,
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Точность'),
                      if (_sortColumn == 2)
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                    ],
                  ),
                  numeric: true,
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Ошибки'),
                      if (_sortColumn == 3)
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                    ],
                  ),
                  numeric: true,
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Рейтинг'),
                      if (_sortColumn == 4)
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                    ],
                  ),
                  numeric: true,
                  onSort: (i, asc) => _onSort(i, asc),
                ),
                DataColumn(
                  label: Row(
                    children: [
                      const Text('Последняя сессия'),
                      if (_sortColumn == 5)
                        Icon(
                          _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 12,
                        ),
                    ],
                  ),
                  onSort: (i, asc) => _onSort(i, asc),
                ),
              ],
              source: source,
            ),
          ),
        ],
      ),
    );
  }
}
