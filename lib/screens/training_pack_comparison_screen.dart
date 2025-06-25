import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../services/training_pack_storage_service.dart';
import '../models/training_pack.dart';
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
  final TrainingPack? editingPack;
  final TextEditingController controller;
  final void Function(TrainingPackStats) onStartEdit;
  final void Function(TrainingPackStats, String) onSubmitEdit;
  final Future<void> Function(TrainingPackStats, String) onAction;
  final Future<void> Function(TrainingPackStats) showMenu;

  _PackDataSource({
    required this.stats,
    required this.onOpen,
    required this.maxAccuracy,
    required this.minAccuracy,
    required this.now,
    required this.editingPack,
    required this.controller,
    required this.onStartEdit,
    required this.onSubmitEdit,
    required this.onAction,
    required this.showMenu,
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
      onLongPress: () => showMenu(s),
      cells: [
        editingPack == s.pack
            ? DataCell(
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (v) => onSubmitEdit(s, v),
                ),
              )
            : DataCell(
                Tooltip(
                  message: 'Открыть обзор пака',
                  child: Text(s.pack.name),
                ),
                onTap: () => onStartEdit(s),
              ),
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
        DataCell(
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            onSelected: (v) => onAction(s, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Переименовать')),
              PopupMenuItem(value: 'delete', child: Text('Удалить')),
              PopupMenuItem(value: 'duplicate', child: Text('Дублировать')),
            ],
          ),
        ),
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
  TrainingPack? _editingPack;
  final TextEditingController _controller = TextEditingController();

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  void _startEdit(TrainingPackStats s) {
    setState(() {
      _editingPack = s.pack;
      _controller.text = s.pack.name;
    });
  }

  Future<void> _submitEdit(TrainingPack pack, String name) async {
    setState(() => _editingPack = null);
    await context.read<TrainingPackStorageService>().renamePack(pack, name);
  }

  Future<void> _deletePack(TrainingPack pack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить пакет «${pack.name}»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await context.read<TrainingPackStorageService>().removePack(pack);
    }
  }

  Future<void> _duplicatePack(TrainingPack pack) async {
    await context.read<TrainingPackStorageService>().duplicatePack(pack);
  }

  Future<void> _showRowMenu(TrainingPackStats s) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(s.pack.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'rename'),
            child: const Text('Переименовать'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Удалить'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'duplicate'),
            child: const Text('Дублировать'),
          ),
        ],
      ),
    );
    if (result != null) {
      await _handleAction(s, result);
    }
  }

  Future<void> _handleAction(TrainingPackStats s, String action) async {
    if (action == 'rename') {
      _startEdit(s);
    } else if (action == 'delete') {
      await _deletePack(s.pack);
    } else if (action == 'duplicate') {
      await _duplicatePack(s.pack);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      editingPack: _editingPack,
      controller: _controller,
      onStartEdit: _startEdit,
      onSubmitEdit: (s, v) => _submitEdit(s.pack, v),
      onAction: _handleAction,
      showMenu: _showRowMenu,
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
                  label: Tooltip(
                    message: 'Средний рейтинг всех рук в паке (1–5)',
                    child: Row(
                      children: [
                        const Text('Рейтинг'),
                        if (_sortColumn == 4)
                          Icon(
                            _ascending ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12,
                          ),
                      ],
                    ),
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
                const DataColumn(label: SizedBox.shrink()),
              ],
              source: source,
            ),
          ),
        ],
      ),
    );
  }
}
