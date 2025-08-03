import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/progress_chip.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../helpers/date_utils.dart';
import '../models/game_type.dart';

import '../services/training_pack_storage_service.dart';
import '../models/training_pack.dart';
import '../models/training_pack_stats.dart';
import '../models/pack_chart_sort_option.dart';
import '../theme/app_colors.dart';
import 'training_pack_review_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/pack_next_step_card.dart';
import '../widgets/difficulty_chip.dart';
import '../widgets/info_tooltip.dart';
import '../helpers/color_utils.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/sync_status_widget.dart';
import 'training_pack_comparison/pack_comparison_filters.dart';
import 'training_pack_comparison/pack_completion_bar_chart.dart';

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
    final pct = s.pack.pctComplete;
    final progressColor = progress < 0.5
        ? Colors.redAccent
        : progress < 0.8
            ? AppColors.accent
            : Colors.greenAccent;
    final selectedRow = selected.contains(s.pack);
    return DataRow(
      selected: selectedRow,
      color: forgotten
          ? WidgetStateProperty.all(Colors.grey.shade800)
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
                      if (!s.pack.isBuiltIn) ...[
                        InfoTooltip(
                          message: s.pack.colorTag.isEmpty
                              ? 'No color tag'
                              : 'Color tag ${s.pack.colorTag} (tap to edit)',
                          child: s.pack.colorTag.isEmpty
                              ? const Icon(Icons.circle_outlined, color: Colors.white24)
                              : Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: colorFromHex(s.pack.colorTag),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(child: Text(s.pack.isBuiltIn ? '📦 ${s.pack.name}' : s.pack.name)),
                      const SizedBox(width: 4),
                      DifficultyChip(s.pack.difficulty),
                      const SizedBox(width: 4),
                      InfoTooltip(
                        message: pct == 1
                            ? 'Completed!'
                            : 'Solved ${s.pack.solved} of ${s.pack.hands.length} hands',
                        child: ProgressChip(pct),
                      ),
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
                  '${DateFormat('d MMMM yyyy', Intl.getCurrentLocale()).format(s.lastSession!)}'
              : 'Нет данных',
          child: Text(s.lastSession != null
              ? DateFormat('dd.MM', Intl.getCurrentLocale()).format(s.lastSession!)
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
              if (!s.pack.isBuiltIn)
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
  final int _rowsPerPage = 10;
  PackChartSort _chartSort = PackChartSort.progress;
  GameType? _typeFilter;
  int _diffFilter = 0;
  String _colorFilter = 'All';
  Color _lastColor = Colors.blue;
  static const _lastColorKey = 'pack_last_color';
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) {
        setState(() {
          _prefs = p;
          _diffFilter = p.getInt('pack_diff_filter') ?? 0;
          _colorFilter = p.getString('pack_color_filter') ?? 'All';
          _lastColor = colorFromHex(p.getString(_lastColorKey) ?? '#2196F3');
        });
      }
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
          if (!s.pack.isBuiltIn)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'rename'),
              child: const Text('Переименовать'),
            ),
          if (!s.pack.isBuiltIn)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'delete'),
              child: const Text('Удалить'),
            ),
          if (!s.pack.isBuiltIn)
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
        s.lastSession != null
            ? DateFormat('dd.MM', Intl.getCurrentLocale()).format(s.lastSession!)
            : '-',
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

  Future<void> _setColorTag() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final color = await showColorPickerDialog(
      context,
      initialColor: _lastColor,
    );
    if (color == null) return;
    final hex = colorToHex(color);
    setState(() => _lastColor = color);
    await prefs.setString(_lastColorKey, hex);
    final service = context.read<TrainingPackStorageService>();
    for (final p in _selected) {
      await service.setColorTag(p, hex);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final allPacks = context.watch<TrainingPackStorageService>().packs;
    var packs = _typeFilter == null
        ? allPacks
        : [for (final p in allPacks) if (p.gameType == _typeFilter) p];
    if (_diffFilter > 0) {
      packs = [for (final p in packs) if (p.difficulty == _diffFilter) p];
    }
    if (_colorFilter != 'All') {
      if (_colorFilter == 'None') {
        packs = [for (final p in packs) if (p.colorTag.isEmpty) p];
      } else if (_colorFilter.startsWith('#')) {
        packs = [for (final p in packs) if (p.colorTag == _colorFilter) p];
      } else {
        const map = {
          'Red': '#F44336',
          'Blue': '#2196F3',
          'Orange': '#FF9800',
          'Green': '#4CAF50',
          'Purple': '#9C27B0',
          'Grey': '#9E9E9E',
        };
        final hex = map[_colorFilter];
        if (hex != null) {
          packs = [for (final p in packs) if (p.colorTag == hex) p];
        }
      }
    }
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
        actions: [SyncStatusIcon.of(context)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _exportCsv,
        child: const Icon(Icons.share),
      ),
      body: Column(
        children: [
          PackComparisonFilters(
            forgottenOnly: _forgottenOnly,
            onForgottenChanged: (v) => setState(() => _forgottenOnly = v),
            chartSort: _chartSort,
            onSortChanged: (v) {
              if (v != null) setState(() => _chartSort = v);
            },
            typeFilter: _typeFilter,
            onTypeChanged: (v) => setState(() => _typeFilter = v),
            diffFilter: _diffFilter,
            onDiffChanged: (value) async {
              setState(() => _diffFilter = value);
              final prefs = _prefs ?? await SharedPreferences.getInstance();
              if (value == 0) {
                await prefs.remove('pack_diff_filter');
              } else {
                await prefs.setInt('pack_diff_filter', value);
              }
            },
            colorFilter: _colorFilter,
            onColorChanged: (value) async {
              final val = value ?? 'All';
              final prefs = _prefs ?? await SharedPreferences.getInstance();
              if (val == 'Custom') {
                final color = await showColorPickerDialog(
                  context,
                  initialColor: _lastColor,
                );
                if (color == null) return;
                final hex = colorToHex(color);
                setState(() {
                  _colorFilter = hex;
                  _lastColor = color;
                });
                await prefs.setString(_lastColorKey, hex);
                await prefs.setString('pack_color_filter', hex);
                return;
              }
              setState(() => _colorFilter = val);
              if (val == 'All') {
                await prefs.remove('pack_color_filter');
              } else {
                await prefs.setString('pack_color_filter', val);
              }
            },
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
                    key: ValueKey(nextPack.name),
                    pack: nextPack,
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
                        onPressed: _setColorTag,
                        child: const Text('🎨 Color Tag'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          final service = context.read<TrainingPackStorageService>();
                          for (final p in _selected) {
                            await service.setColorTag(p, '');
                          }
                          await service.save();
                          _clearSelection();
                        },
                        child: const Text('🧹 Clear Color'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _deleteSelected,
                        child: const Text('Удалить'),
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

