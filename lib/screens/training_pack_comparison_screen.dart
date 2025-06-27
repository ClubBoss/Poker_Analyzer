import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/game_type.dart';

import '../services/training_pack_storage_service.dart';
import '../models/training_pack.dart';
import '../models/training_pack_stats.dart';
import '../models/pack_chart_sort_option.dart';
import '../theme/app_colors.dart';
import '../helpers/color_utils.dart';
import '../widgets/color_tag_dialog.dart';
import 'training_pack_review_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/pack_next_step_card.dart';

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
  final Set<TrainingPack> selected;
  final void Function(TrainingPack) onToggle;
  final bool selectionMode;

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
    required this.selected,
    required this.onToggle,
    required this.selectionMode,
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
    final progress = s.total > 0 ? (s.total - s.mistakes) / s.total : 0.0;
    final progressColor = progress < 0.5
        ? Colors.redAccent
        : progress < 0.8
            ? Colors.orangeAccent
            : Colors.greenAccent;
    final selectedRow = selected.contains(s.pack);
    return DataRow(
      selected: selectedRow,
      color: forgotten
          ? MaterialStateProperty.all(Colors.grey.shade800)
          : null,
      onSelectChanged: (_) =>
          selectionMode ? onToggle(s.pack) : onOpen(s),
      onLongPress: () =>
          selectionMode ? onToggle(s.pack) : showMenu(s),
      cells: [
        DataCell(Checkbox(
          value: selectedRow,
          onChanged: (_) => onToggle(s.pack),
        )),
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
                  child: Row(
                    children: [
                      if (!s.pack.isBuiltIn)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colorFromHex(s.pack.colorTag),
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (!s.pack.isBuiltIn) const SizedBox(width: 6),
                      Text(s.pack.isBuiltIn ? '📦 ${s.pack.name}' : s.pack.name),
                    ],
                  ),
                ),
                onTap: () => selectionMode ? onToggle(s.pack) : onStartEdit(s),
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
        DataCell(
          Tooltip(
            message: '${s.total - s.mistakes} из ${s.total} выполнено верно',
            child: SizedBox(
              width: 120,
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: progressColor),
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(Text(s.mistakes.toString())),
        DataCell(Text('–${s.totalEvLoss.toStringAsFixed(1)} bb',
            style: TextStyle(
                color: s.totalEvLoss > 0 ? Colors.red : Colors.green))),
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
            itemBuilder: (_) => [
              if (!s.pack.isBuiltIn)
                const PopupMenuItem(value: 'rename', child: Text('Переименовать')),
              if (!s.pack.isBuiltIn)
                const PopupMenuItem(value: 'delete', child: Text('Удалить')),
              const PopupMenuItem(value: 'duplicate', child: Text('Дублировать')),
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
  final Set<TrainingPack> _selected = {};
  int _firstRowIndex = 0;
  int _rowsPerPage = 10;
  PackChartSort _chartSort = PackChartSort.progress;
  GameType? _typeFilter;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _prefs = p);
    });
  }

  void _toggleSelect(TrainingPack pack) {
    setState(() {
      if (_selected.contains(pack)) {
        _selected.remove(pack);
      } else {
        _selected.add(pack);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  void _onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumn = columnIndex;
      _ascending = ascending;
    });
  }

  void _startEdit(TrainingPackStats s) {
    if (s.pack.isBuiltIn) return;
    setState(() {
      _editingPack = s.pack;
      _controller.text = s.pack.name;
    });
  }

  Future<void> _submitEdit(TrainingPack pack, String name) async {
    if (pack.isBuiltIn) return;
    setState(() => _editingPack = null);
    await context.read<TrainingPackStorageService>().renamePack(pack, name);
  }

  Future<void> _deletePack(TrainingPack pack) async {
    if (pack.isBuiltIn) return;
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
      final result = await context.read<TrainingPackStorageService>().removePack(pack);
      if (result != null) {
        _showUndoDelete(result.\$1, result.\$2);
      }
    }
  }

  Future<void> _duplicatePack(TrainingPack pack) async {
    await context.read<TrainingPackStorageService>().duplicatePack(pack);
  }

  void _showUndoDelete(TrainingPack pack, int index) {
    final snack = SnackBar(
      content: const Text('Пакет удалён'),
      action: SnackBarAction(
        label: 'Отмена',
        onPressed: () =>
            context.read<TrainingPackStorageService>().restorePack(pack, index),
      ),
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
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
        case 4:
          cmp = a.mistakes.compareTo(b.mistakes);
          break;
        case 5:
          cmp = a.totalEvLoss.compareTo(b.totalEvLoss);
          break;
        case 6:
          cmp = a.rating.compareTo(b.rating);
          break;
        case 7:
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

  Future<void> _exportCsv([List<TrainingPackStats>? custom]) async {
    final packs = context.read<TrainingPackStorageService>().packs;
    final stats = custom ?? _sortedStats(packs);
    if (stats.isEmpty) return;
    final rows = <List<dynamic>>[];
    rows.add(['Название', 'Рук', 'Точность', 'Ошибки', 'Потеря EV', 'Рейтинг', 'Последняя сессия']);
    var sumTotal = 0;
    var sumMistakes = 0;
    var sumAcc = 0.0;
    var sumRating = 0.0;
    var sumEvLoss = 0.0;
    for (final s in stats) {
      rows.add([
        s.pack.name,
        s.total,
        '${s.accuracy.toStringAsFixed(1)}%',
        s.mistakes,
        '–${s.totalEvLoss.toStringAsFixed(1)} bb',
        s.rating.toStringAsFixed(1),
        s.lastSession != null ? DateFormat('dd.MM').format(s.lastSession!) : '-',
      ]);
      sumTotal += s.total;
      sumMistakes += s.mistakes;
      sumAcc += s.accuracy;
      sumRating += s.rating;
      sumEvLoss += s.totalEvLoss;
    }
    final avgAcc = stats.isNotEmpty ? sumAcc / stats.length : 0.0;
    final avgRating = stats.isNotEmpty ? sumRating / stats.length : 0.0;
    rows.add([
      'Σ',
      sumTotal,
      '${avgAcc.toStringAsFixed(1)}%',
      sumMistakes,
      '–${sumEvLoss.toStringAsFixed(1)} bb',
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

  String _packReport(TrainingPack pack) {
    final stats = TrainingPackStats.fromPack(pack);
    final buffer = StringBuffer()
      ..writeln('# ${pack.name}')
      ..writeln('- Кол-во рук: ${stats.total}')
      ..writeln('- Точность: ${stats.accuracy.toStringAsFixed(1)}%')
      ..writeln('- Ошибок: ${stats.mistakes}')
      ..writeln();
    final last = pack.history.isNotEmpty ? pack.history.last : null;
    if (last != null) {
      final mistakes = [for (final t in last.tasks) if (!t.correct) t.question];
      if (mistakes.isNotEmpty) {
        buffer.writeln('## Ошибочные руки');
        for (final m in mistakes) {
          buffer.writeln('- $m');
        }
      }
    }
    return buffer.toString();
  }

  Future<void> _exportMarkdown(List<TrainingPackStats> stats) async {
    if (stats.isEmpty) return;
    final buffer = StringBuffer();
    for (final s in stats) {
      buffer.writeln(_packReport(s.pack));
      buffer.writeln();
    }
    final dir = await getTemporaryDirectory();
    final name =
        'pack_report_${DateFormat("yyyy-MM-dd_HH-mm").format(DateTime.now())}.md';
    final file = File('${dir.path}/$name');
    await file.writeAsString(buffer.toString());
    try {
      await Share.shareXFiles([XFile(file.path)], text: name);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Markdown экспортирован')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта Markdown')));
      }
    }
  }

  Future<void> _deleteSelected() async {
    final list = _selected.toList();
    for (final pack in list) {
      if (!pack.isBuiltIn) await _deletePack(pack);
    }
    _clearSelection();
  }

  Future<void> _colorSelected() async {
    final hex = await showColorTagDialog(context);
    if (hex == null) return;
    final service = context.read<TrainingPackStorageService>();
    for (final p in _selected) {
      final updated = TrainingPack(
        name: p.name,
        description: p.description,
        category: p.category,
        gameType: p.gameType,
        colorTag: hex,
        isBuiltIn: p.isBuiltIn,
        tags: p.tags,
        hands: p.hands,
        spots: p.spots,
        difficulty: p.difficulty,
        history: p.history,
      );
      await service.save(updated);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final allPacks = context.watch<TrainingPackStorageService>().packs;
    final packs = _typeFilter == null
        ? allPacks
        : [for (final p in allPacks) if (p.gameType == _typeFilter) p];
    final allStats = [for (final p in packs) TrainingPackStats.fromPack(p)];
    final sumTotal = allStats.fold<int>(0, (s, e) => s + e.total);
    final sumMistakes = allStats.fold<int>(0, (s, e) => s + e.mistakes);
    final sumEvLoss = allStats.fold<double>(0, (s, e) => s + e.totalEvLoss);
    final avgAcc =
        allStats.isNotEmpty ? allStats.fold<double>(0, (s, e) => s + e.accuracy) / allStats.length : 0.0;
    final avgRating =
        allStats.isNotEmpty ? allStats.fold<double>(0, (s, e) => s + e.rating) / allStats.length : 0.0;
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

    TrainingPack? nextPack;
    double nextProgress = 1.0;
    if (_prefs != null) {
      for (final p in packs) {
        final idx = _prefs!.getInt('training_progress_${p.name}') ?? 0;
        if (p.hands.isEmpty || idx >= p.hands.length) continue;
        final ratio = idx / p.hands.length;
        if (nextPack == null || ratio < nextProgress) {
          nextPack = p;
          nextProgress = ratio;
        }
      }
    }

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
      selected: _selected,
      onToggle: _toggleSelect,
      selectionMode: _selected.isNotEmpty,
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
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Сортировка',
                  style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              DropdownButton<PackChartSort>(
                value: _chartSort,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: [
                  for (final s in PackChartSort.values)
                    DropdownMenuItem(value: s, child: Text(s.label))
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _chartSort = v);
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Тип', style: TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              DropdownButton<GameType?>(
                value: _typeFilter,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Все')),
                  DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
                  DropdownMenuItem(value: GameType.cash, child: Text('Cash Game')),
                ],
                onChanged: (v) => setState(() => _typeFilter = v),
              ),
            ],
          ),
        ),
        PackCompletionBarChart(
          stats: stats,
          hideCompleted: false,
          forgottenOnly: _forgottenOnly,
          sort: _chartSort,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => SlideTransition(
              position: Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                  .animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: nextPack != null
                ? PackNextStepCard(
                    key: ValueKey(nextPack!.name),
                    pack: nextPack!,
                    progress: nextProgress,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _selected.isNotEmpty ? 48 : 0,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _selected.isNotEmpty
                ? Row(
                    children: [
                      ElevatedButton(
                        onPressed: _deleteSelected,
                        child: const Text('Удалить'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _colorSelected,
                        child: const Text('🎨 Color Tag'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () =>
                            _exportCsv([for (final s in stats) if (_selected.contains(s.pack)) s]).then((_) => _clearSelection()),
                        child: const Text('CSV'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () =>
                            _exportMarkdown([for (final s in stats) if (_selected.contains(s.pack)) s]).then((_) => _clearSelection()),
                        child: const Text('MD'),
                      ),
                    ],
                  )
                : null,
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PaginatedDataTable(
                    sortColumnIndex: _sortColumn,
                    sortAscending: _ascending,
                    rowsPerPage: _rowsPerPage,
                    onPageChanged: (i) => setState(() => _firstRowIndex = i),
                    columns: [
                      DataColumn(
                        label: Row(
                          children: [
                            Checkbox(
                              value: stats
                                  .skip(_firstRowIndex)
                                  .take(_rowsPerPage)
                                  .every((s) => _selected.contains(s.pack)) &&
                                  stats.isNotEmpty,
                              onChanged: (v) {
                                final visible = stats
                                    .skip(_firstRowIndex)
                                    .take(_rowsPerPage);
                                setState(() {
                                  if (v == true) {
                                    _selected.addAll(
                                        visible.map((e) => e.pack));
                                  } else {
                                    for (final s in visible) {
                                      _selected.remove(s.pack);
                                    }
                                  }
                                });
                              },
                            ),
                            const Text('Все'),
                          ],
                        ),
                      ),
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
                  const DataColumn(label: Text('Прогресс')),
                  DataColumn(
                    label: Row(
                      children: [
                        const Text('Ошибки'),
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
                    label: Tooltip(
                      message: 'Суммарная потеря EV в паке',
                      child: Row(
                        children: [
                          const Text('Потеря EV'),
                          if (_sortColumn == 5)
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
                    label: Tooltip(
                      message: 'Средний рейтинг всех рук в паке (1–5)',
                      child: Row(
                        children: [
                          const Text('Рейтинг'),
                          if (_sortColumn == 6)
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
                        if (_sortColumn == 7)
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
                DataTable(
                  headingRowHeight: 0,
                  columns: const [
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink(), numeric: true),
                    DataColumn(label: SizedBox.shrink(), numeric: true),
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink(), numeric: true),
                    DataColumn(label: SizedBox.shrink(), numeric: true),
                    DataColumn(label: SizedBox.shrink(), numeric: true),
                    DataColumn(label: SizedBox.shrink()),
                    DataColumn(label: SizedBox.shrink()),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        const DataCell(SizedBox.shrink()),
                        const DataCell(Text('Σ')),
                        DataCell(Text(sumTotal.toString())),
                        DataCell(Text('${avgAcc.toStringAsFixed(1)}%')),
                        DataCell(Text('${((sumTotal - sumMistakes) / (sumTotal > 0 ? sumTotal : 1) * 100).toStringAsFixed(1)}%')),
                        DataCell(Text(sumMistakes.toString())),
                        DataCell(Text('–${sumEvLoss.toStringAsFixed(1)} bb')),
                        DataCell(Text(avgRating.toStringAsFixed(1))),
                        const DataCell(Text('-')),
                        const DataCell(SizedBox.shrink()),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PackCompletionBarChart extends StatefulWidget {
  final List<TrainingPackStats> stats;
  final bool hideCompleted;
  final bool forgottenOnly;
  final PackChartSort sort;

  const PackCompletionBarChart({
    super.key,
    required this.stats,
    required this.hideCompleted,
    required this.forgottenOnly,
    required this.sort,
  });

  @override
  State<PackCompletionBarChart> createState() => _PackCompletionBarChartState();
}

class _PackCompletionBarChartState extends State<PackCompletionBarChart>
    with SingleTickerProviderStateMixin {
  int? _index;
  Offset? _pos;
  Timer? _timer;
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _show(int index, Offset pos) {
    if (_index == index) {
      _hide();
      return;
    }
    _timer?.cancel();
    setState(() {
      _index = index;
      _pos = pos;
    });
    _anim.forward(from: 0);
    _timer = Timer(const Duration(seconds: 2), _hide);
  }

  void _hide() {
    _timer?.cancel();
    if (_index != null) {
      setState(() => _index = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filtered = stats.where((s) {
      final progress = s.total > 0 ? (s.total - s.mistakes) / s.total : 0.0;
      final completed = progress >= 1.0;
      final forgotten =
          s.lastSession == null || now.difference(s.lastSession!).inDays >= 7;
      if (hideCompleted && completed) return false;
      if (forgottenOnly && !forgotten) return false;
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (widget.sort) {
        case PackChartSort.lastSession:
          final da = a.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.lastSession ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        case PackChartSort.handsPlayed:
          return b.total.compareTo(a.total);
        case PackChartSort.progress:
        default:
          final pa = a.total > 0 ? (a.total - a.mistakes) * 100 / a.total : 0.0;
          final pb = b.total > 0 ? (b.total - b.mistakes) * 100 / b.total : 0.0;
          return pb.compareTo(pa);
      }
    });

    if (filtered.isEmpty) {
      return const SizedBox.shrink();
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < filtered.length; i++) {
      final stat = filtered[i];
      final percent =
          stat.total > 0 ? (stat.total - stat.mistakes) * 100 / stat.total : 0.0;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: percent,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                colors: [Colors.lightGreenAccent, Colors.green],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          BarChart(
            BarChartData(
              maxY: 100,
              minY: 0,
              barGroups: groups,
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.spot == null) {
                    return;
                  }
                  _show(
                    response!.spot!.touchedBarGroupIndex,
                    response.touchLocation,
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= filtered.length) {
                        return const SizedBox.shrink();
                      }
                      return Transform.rotate(
                        angle: -1.5708,
                        child: Text(
                          filtered[idx].pack.name,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
          if (_index != null && _pos != null && _index! < filtered.length)
            _BarTooltip(
              position: (context.findRenderObject() as RenderBox)
                      .globalToLocal(_pos!) -
                  const Offset(40, 60),
              stats: filtered[_index!],
              animation: _anim,
            ),
        ],
      ),
    );
  }
}

class _BarTooltip extends StatefulWidget {
  final Offset position;
  final TrainingPackStats stats;
  final Animation<double> animation;

  const _BarTooltip({
    required this.position,
    required this.stats,
    required this.animation,
  });

  @override
  State<_BarTooltip> createState() => _BarTooltipState();
}

class _BarTooltipState extends State<_BarTooltip> {
  @override
  Widget build(BuildContext context) {
    final s = widget.stats;
    final completed = s.total - s.mistakes;
    final percent = s.total > 0 ? completed * 100 / s.total : 0.0;
    final remain = s.total - completed;
    final last = s.lastSession != null
        ? DateFormat('dd.MM.yyyy').format(s.lastSession!)
        : 'нет данных';
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: FadeTransition(
        opacity: widget.animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.8, end: 1.0).animate(widget.animation),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$completed/${s.total} (осталось $remain)',
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Text(
                    last,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
