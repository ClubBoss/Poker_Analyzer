import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import '../models/summary_result.dart';
import 'dart:io';

import '../helpers/date_utils.dart';

import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../models/mistake_severity.dart';
import '../models/mistake_sort_option.dart';
import 'tag_insight_screen.dart';
import '../theme/app_colors.dart';
import '../services/ignored_mistake_service.dart';
import '../services/tag_service.dart';
import '../helpers/color_utils.dart';
import '../widgets/saved_hand_list_view.dart';
import '../widgets/mistake_summary_section.dart';
import '../widgets/mistake_empty_state.dart';
import '../widgets/common/mistake_trend_chart.dart';

enum _ChartMode { daily, weekly }
import '../widgets/saved_hand_viewer_dialog.dart';
import '../widgets/saved_hand_tile.dart';
import '../widgets/sync_status_widget.dart';

/// Displays a list of tags sorted by mistake count.
///
/// Information is pulled from [EvaluationExecutorService.summarizeHands]. Each
/// tile shows how many errors were made for that tag. Selecting a tag opens a
/// filtered [SavedHandListView] showing only the mistaken hands for the chosen
/// tag.
class TagMistakeOverviewScreen extends StatefulWidget {
  final String dateFilter;
  const TagMistakeOverviewScreen({super.key, required this.dateFilter});

  @override
  State<TagMistakeOverviewScreen> createState() =>
      _TagMistakeOverviewScreenState();
}

class _TagMistakeOverviewScreenState extends State<TagMistakeOverviewScreen> {
  static const _tagsKey = 'tag_filter_tags';
  static const _levelsKey = 'tag_filter_levels';
  static const _startKey = 'tag_filter_range_start';
  static const _endKey = 'tag_filter_range_end';
  static const _cmpStartKey = 'tag_compare_start';
  static const _cmpEndKey = 'tag_compare_end';
  static const _prevKey = 'tag_compare_prev';
  static const _chartModeKey = 'tag_chart_mode';
  MistakeSortOption _sort = MistakeSortOption.count;
  final Set<String> _activeTags = {};
  DateTimeRange? _range;
  DateTimeRange? _compareRange;
  bool _comparePrevious = false;
  final GlobalKey _chartKey = GlobalKey();
  final Set<MistakeSeverity> _levels = {
    MistakeSeverity.high,
    MistakeSeverity.medium,
    MistakeSeverity.low
  };
  _ChartMode _chartMode = _ChartMode.daily;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final tags = prefs.getStringList(_tagsKey);
    if (tags != null) _activeTags.addAll(tags);
    final levels = prefs.getStringList(_levelsKey);
    if (levels != null && levels.isNotEmpty) {
      _levels
        ..clear()
        ..addAll(levels
            .map((e) => MistakeSeverity.values.firstWhere((m) => m.name == e)));
    }
    final start = prefs.getString(_startKey);
    final end = prefs.getString(_endKey);
    if (start != null && end != null) {
      final s = DateTime.tryParse(start);
      final e = DateTime.tryParse(end);
      if (s != null && e != null) _range = DateTimeRange(start: s, end: e);
    }
    _comparePrevious = prefs.getBool(_prevKey) ?? false;
    if (_comparePrevious) {
      final now = DateTime.now();
      final baseStart = _range?.start ?? now.subtract(const Duration(days: 29));
      final baseEnd = _range?.end ?? now;
      final diff = baseEnd.difference(baseStart).inDays;
      final cmpEnd = baseStart.subtract(const Duration(days: 1));
      final cmpStart = cmpEnd.subtract(Duration(days: diff));
      _compareRange = DateTimeRange(start: cmpStart, end: cmpEnd);
    } else {
      final cs = prefs.getString(_cmpStartKey);
      final ce = prefs.getString(_cmpEndKey);
      if (cs != null && ce != null) {
        final s = DateTime.tryParse(cs);
        final e = DateTime.tryParse(ce);
        if (s != null && e != null) {
          _compareRange = DateTimeRange(start: s, end: e);
        }
      }
    }
    final modeName = prefs.getString(_chartModeKey);
    if (modeName != null) {
      final index = _ChartMode.values.indexWhere((m) => m.name == modeName);
      if (index != -1) _chartMode = _ChartMode.values[index];
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveTags() async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeTags.isEmpty) {
      await prefs.remove(_tagsKey);
    } else {
      await prefs.setStringList(_tagsKey, _activeTags.toList());
    }
  }

  Future<void> _saveLevels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_levelsKey, _levels.map((e) => e.name).toList());
  }

  Future<void> _saveRange() async {
    final prefs = await SharedPreferences.getInstance();
    if (_range == null) {
      await prefs.remove(_startKey);
      await prefs.remove(_endKey);
    } else {
      await prefs.setString(_startKey, _range!.start.toIso8601String());
      await prefs.setString(_endKey, _range!.end.toIso8601String());
    }
  }

  Future<void> _saveCompareRange() async {
    final prefs = await SharedPreferences.getInstance();
    if (_compareRange == null) {
      await prefs.remove(_cmpStartKey);
      await prefs.remove(_cmpEndKey);
    } else {
      await prefs.setString(
          _cmpStartKey, _compareRange!.start.toIso8601String());
      await prefs.setString(_cmpEndKey, _compareRange!.end.toIso8601String());
    }
  }

  Future<void> _saveComparePrevious() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prevKey, _comparePrevious);
  }

  DateTimeRange _calcPrevRange() {
    final now = DateTime.now();
    final start = _range?.start ?? now.subtract(const Duration(days: 29));
    final end = _range?.end ?? now;
    final diff = end.difference(start).inDays;
    final cmpEnd = start.subtract(const Duration(days: 1));
    final cmpStart = cmpEnd.subtract(Duration(days: diff));
    return DateTimeRange(start: cmpStart, end: cmpEnd);
  }

  void _toggleComparePrevious(bool v) {
    setState(() {
      _comparePrevious = v;
      if (v) {
        _compareRange = _calcPrevRange();
      } else {
        _compareRange = null;
      }
    });
    _saveComparePrevious();
    _saveCompareRange();
  }

  Future<void> _setChartMode(_ChartMode mode) async {
    setState(() => _chartMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chartModeKey, mode.name);
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String get _rangeLabel {
    if (_range == null) return 'Период';
    final start = formatDate(_range!.start);
    final end = formatDate(_range!.end);
    return start == end ? start : '$start – $end';
  }

  String get _compareLabel {
    if (_comparePrevious) return 'Предыдущий период';
    if (_compareRange == null) return 'Сравнить периоды';
    final s = formatDate(_compareRange!.start);
    final e = formatDate(_compareRange!.end);
    return s == e ? s : '$s – $e';
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final initial = _range ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        if (_comparePrevious) {
          final diff = picked.end.difference(picked.start).inDays;
          final cmpEnd = picked.start.subtract(const Duration(days: 1));
          final cmpStart = cmpEnd.subtract(Duration(days: diff));
          _compareRange = DateTimeRange(start: cmpStart, end: cmpEnd);
        }
      });
      _saveRange();
      if (_comparePrevious) {
        _saveCompareRange();
      }
    }
  }

  Future<void> _pickCompareRange() async {
    final now = DateTime.now();
    final initial = _compareRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() => _compareRange = picked);
      _saveCompareRange();
    }
  }

  void _toggleLevel(MistakeSeverity level) {
    setState(() {
      if (_levels.contains(level)) {
        _levels.remove(level);
      } else {
        _levels.add(level);
      }
      if (_levels.isEmpty) {
        _levels.add(level);
      }
    });
    _saveLevels();
  }

  void _resetLevels() {
    setState(() {
      _levels
        ..clear()
        ..addAll(MistakeSeverity.values);
    });
    _saveLevels();
  }

  void _resetCompare() {
    setState(() {
      _compareRange = null;
      _comparePrevious = false;
    });
    _saveCompareRange();
    _saveComparePrevious();
  }

  void _openDay(DateTime day) {
    final allHands = context.read<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final filtered = [
      for (final h in allHands)
        if ((widget.dateFilter == 'Все' ||
                (widget.dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
                (widget.dateFilter == '7 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
                (widget.dateFilter == '30 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 30))))) &&
            (_range == null ||
                (!h.date.isBefore(_range!.start) &&
                    !h.date.isAfter(_range!.end))) &&
            _sameDay(h.date, day))
          h
    ];
    final summary =
        context.read<EvaluationExecutorService>().summarizeHands(filtered);
    final ignored = context.read<IgnoredMistakeService>().ignored;
    final service = context.read<EvaluationExecutorService>();
    final baseEntries = summary.mistakeTagFrequencies.entries
        .where((e) => !ignored.contains('tag:${e.key}'))
        .toList();
    final visibleTags = _activeTags.isNotEmpty
        ? _activeTags
        : {
            for (final e in baseEntries)
              if (_levels.contains(service.classifySeverity(e.value))) e.key
          };
    final hands = [
      for (final h in filtered)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase() &&
            (visibleTags.isEmpty || h.tags.any(visibleTags.contains)))
          h
    ];
    if (hands.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет ошибок в этот день')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DailySeverityHandsScreen(
          day: day,
          tags: _activeTags.isNotEmpty ? _activeTags : null,
          dateFilter: widget.dateFilter,
          dateRange: _range,
          levels: _levels,
        ),
      ),
    );
  }

  Widget _buildLegend(Map<String, Color> colors, bool overlay, bool primary) {
    return Wrap(
      spacing: 8,
      children: [
        for (final entry in colors.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: entry.value,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                overlay ? entry.key : (primary ? 'Основной' : 'Сравнение'),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
      ],
    );
  }

  Future<Uint8List?> _captureChart() async {
    final boundary = _chartKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _exportPdf(BuildContext context, SummaryResult summary,
      List<MapEntry<String, int>> entries) async {
    final chartBytes = await _captureChart();
    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final date = formatDateTime(DateTime.now());
    final service = context.read<EvaluationExecutorService>();
    final rows = [
      for (final e in entries)
        [e.key, e.value.toString(), service.classifySeverity(e.value).label]
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          final items = <pw.Widget>[
            pw.Text('Ошибки по тегам',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 8),
            pw.Text(date, style: pw.TextStyle(font: regularFont)),
          ];
          if (chartBytes != null) {
            items.add(pw.SizedBox(height: 16));
            items.add(pw.Image(pw.MemoryImage(chartBytes),
                width: PdfPageFormat.a4.availableWidth));
          }
          items.add(pw.SizedBox(height: 16));
          if (entries.isEmpty) {
            items.add(pw.Text('Ошибок не найдено за выбранный период.',
                style: pw.TextStyle(font: regularFont)));
          } else {
            final mistakes = summary.incorrect;
            final total = summary.totalHands;
            final accuracy = summary.accuracy;
            final mistakePercent =
                total > 0 ? mistakes / total * 100 : 0.0;
            items.addAll([
              pw.Text('Ошибки: $mistakes',
                  style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 4),
              pw.Text('Средняя точность: ${accuracy.toStringAsFixed(1)}%',
                  style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'Доля рук с ошибками: ${mistakePercent.toStringAsFixed(1)}%',
                  style: pw.TextStyle(font: regularFont)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: const ['Тег', 'Ошибки', 'Уровень'],
                data: rows,
              ),
            ]);
          }
          return items;
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tag_summary.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'tag_summary.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final hands = [
      for (final h in allHands)
        if ((widget.dateFilter == 'Все' ||
                (widget.dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
                (widget.dateFilter == '7 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
                (widget.dateFilter == '30 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 30))))) &&
            (_range == null ||
                (!h.date.isBefore(_range!.start) &&
                    !h.date.isAfter(_range!.end))))
          h
    ];
    final summary =
        context.read<EvaluationExecutorService>().summarizeHands(hands);
    final ignored = context.watch<IgnoredMistakeService>().ignored;
    final service = context.read<EvaluationExecutorService>();
    final baseEntries = summary.mistakeTagFrequencies.entries
        .where((e) => !ignored.contains('tag:${e.key}'))
        .toList();
    final tags = [for (final e in baseEntries) e.key]..sort();
    final entries = <MapEntry<String, int>>[...baseEntries];
    if (_activeTags.isNotEmpty) {
      entries.removeWhere((e) => !_activeTags.contains(e.key));
    }
    entries.removeWhere(
        (e) => !_levels.contains(service.classifySeverity(e.value)));

    final List<MapEntry<String, int>> cmpEntries = [];

    int score(MapEntry<String, int> e) {
      final severity = service.classifySeverity(e.value);
      switch (severity) {
        case MistakeSeverity.high:
          return 2;
        case MistakeSeverity.medium:
          return 1;
        case MistakeSeverity.low:
        default:
          return 0;
      }
    }

    if (_sort == MistakeSortOption.severity) {
      entries.sort((a, b) {
        final cmp = score(b).compareTo(score(a));
        if (cmp != 0) return cmp;
        return b.value.compareTo(a.value);
      });
      cmpEntries.sort((a, b) {
        final cmp = score(b).compareTo(score(a));
        if (cmp != 0) return cmp;
        return b.value.compareTo(a.value);
      });
    } else {
      entries.sort((a, b) => b.value.compareTo(a.value));
      cmpEntries.sort((a, b) => b.value.compareTo(a.value));
    }

    final visibleTags = _activeTags.isNotEmpty
        ? _activeTags
        : {
            for (final e in baseEntries)
              if (_levels.contains(service.classifySeverity(e.value))) e.key
          };
    final start = _range?.start ?? now.subtract(const Duration(days: 29));
    final end = _range?.end ?? now;
    final overlayTags = _activeTags.length > 1 && !_comparePrevious;
    final dailyCounts = <DateTime, int>{};
    final tagCounts = <String, Map<DateTime, int>>{};
    for (var d = DateTime(start.year, start.month, start.day);
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      dailyCounts[d] = 0;
      if (overlayTags) {
        for (final t in _activeTags) {
          tagCounts.putIfAbsent(t, () => {})[d] = 0;
        }
      }
    }
    for (final h in hands) {
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      if (visibleTags.isNotEmpty && !h.tags.any(visibleTags.contains)) {
        continue;
      }
      final day = DateTime(h.date.year, h.date.month, h.date.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      if (overlayTags) {
        for (final t in _activeTags) {
          if (h.tags.contains(t)) {
            tagCounts[t]![day] = (tagCounts[t]![day] ?? 0) + 1;
          }
        }
      } else {
        dailyCounts[day] = (dailyCounts[day] ?? 0) + 1;
      }
    }

    var chartCounts = overlayTags ? tagCounts : {'Текущий': dailyCounts};
    final chartColors = overlayTags
        ? {
            for (final t in _activeTags)
              t: colorFromHex(context.read<TagService>().colorOf(t))
          }
        : {'Текущий': Colors.redAccent};

    List<SavedHand> cmpHands = [];
    SummaryResult? cmpSummary;
    Map<String, Map<DateTime, int>> cmpCounts = {};
    Map<String, Color> cmpColors = {};
    Map<DateTime, int> cmpDaily = {};
    if (_compareRange != null) {
      cmpHands = [
        for (final h in allHands)
          if ((widget.dateFilter == 'Все' ||
                  (widget.dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
                  (widget.dateFilter == '7 дней' &&
                      h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
                  (widget.dateFilter == '30 дней' &&
                      h.date
                          .isAfter(now.subtract(const Duration(days: 30))))) &&
              (!_compareRange!.start.isAfter(h.date) &&
                  !_compareRange!.end.isBefore(h.date)))
            h
      ];
      cmpSummary =
          context.read<EvaluationExecutorService>().summarizeHands(cmpHands);
      cmpSummary.mistakeTagFrequencies.entries
          .where((e) => !ignored.contains('tag:${e.key}'));
      final cmpStart = _compareRange!.start;
      final cmpEnd = _compareRange!.end;
      final cmpOverlay = overlayTags;
      cmpDaily = <DateTime, int>{};
      final cmpTags = <String, Map<DateTime, int>>{};
      for (var d = DateTime(cmpStart.year, cmpStart.month, cmpStart.day);
          !d.isAfter(cmpEnd);
          d = d.add(const Duration(days: 1))) {
        cmpDaily[d] = 0;
        if (cmpOverlay) {
          for (final t in _activeTags) {
            cmpTags.putIfAbsent(t, () => {})[d] = 0;
          }
        }
      }
      for (final h in cmpHands) {
        final exp = h.expectedAction;
        final gto = h.gtoAction;
        if (exp == null || gto == null) continue;
        if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
        if (visibleTags.isNotEmpty && !h.tags.any(visibleTags.contains)) {
          continue;
        }
        final day = DateTime(h.date.year, h.date.month, h.date.day);
        if (day.isBefore(cmpStart) || day.isAfter(cmpEnd)) continue;
        if (cmpOverlay) {
          for (final t in _activeTags) {
            if (h.tags.contains(t)) {
              cmpTags[t]![day] = (cmpTags[t]![day] ?? 0) + 1;
            }
          }
        } else {
          cmpDaily[day] = (cmpDaily[day] ?? 0) + 1;
        }
      }
      cmpCounts = cmpOverlay ? cmpTags : {'Предыдущий': cmpDaily};
      cmpColors = cmpOverlay
          ? {
              for (final t in _activeTags)
                t: colorFromHex(context.read<TagService>().colorOf(t))
                    .withValues(alpha: 0.5)
            }
          : {'Предыдущий': Colors.blueAccent};
    }

    if (_comparePrevious && cmpCounts.isNotEmpty) {
      chartCounts = {
        'Текущий': dailyCounts,
        'Предыдущий': cmpDaily,
      };
      chartColors = {
        'Текущий': Colors.redAccent,
        'Предыдущий': Colors.blueAccent,
      };
      cmpCounts = {};
      cmpColors = {};
    }

    if (_chartMode == _ChartMode.weekly) {
      chartCounts = MistakeTrendChart.aggregateByWeek(chartCounts);
      if (cmpCounts.isNotEmpty) {
        cmpCounts = MistakeTrendChart.aggregateByWeek(cmpCounts);
      }
    }

    final sharedPeaks = <DateTime>{};
    if (cmpCounts.isNotEmpty) {
      final totalA = <DateTime, int>{};
      for (final map in chartCounts.values) {
        map.forEach((d, v) => totalA[d] = (totalA[d] ?? 0) + v);
      }
      final totalB = <DateTime, int>{};
      for (final map in cmpCounts.values) {
        map.forEach((d, v) => totalB[d] = (totalB[d] ?? 0) + v);
      }
      if (totalA.isNotEmpty && totalB.isNotEmpty) {
        final maxA = totalA.values.reduce(max);
        final maxB = totalB.values.reduce(max);
        for (final d in totalA.keys) {
          if ((totalA[d] ?? 0) == maxA && (totalB[d] ?? 0) == maxB &&
              maxA > 0 && maxB > 0) {
            sharedPeaks.add(d);
          }
        }
      }
    }

    final diffs = <MapEntry<String, double>>[];
    if (cmpSummary != null) {
      final mapA = {for (final e in entries) e.key: e.value};
      final mapB = {for (final e in cmpEntries) e.key: e.value};
      final allTags = {...mapA.keys, ...mapB.keys}.toList()..sort();
      for (final t in allTags) {
        final a = mapA[t] ?? 0;
        final b = mapB[t] ?? 0;
        final diff = a == 0 ? (b > 0 ? 100.0 : 0.0) : (b - a) / a * 100;
        diffs.add(MapEntry(t, diff));
      }
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: const Text('Ошибки по тегам'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'PDF',
              onPressed: () => _exportPdf(context, summary, entries),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: MistakeSummarySection(summary: summary),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<MistakeSortOption>(
                value: _sort,
                dropdownColor: AppColors.cardBackground,
                style: const TextStyle(color: Colors.white),
                items: const [
                  DropdownMenuItem(
                      value: MistakeSortOption.count,
                      child: Text('По количеству')),
                  DropdownMenuItem(
                      value: MistakeSortOption.severity,
                      child: Text('По уровню')),
                ],
                onChanged: (v) =>
                    setState(() => _sort = v ?? MistakeSortOption.count),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(_rangeLabel),
                  onPressed: _pickRange,
                ),
                if (_range != null)
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white70),
                    onPressed: () {
                      setState(() => _range = null);
                      _saveRange();
                    },
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(_compareLabel),
                  onPressed: _pickCompareRange,
                ),
                if (_compareRange != null)
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 18, color: Colors.white70),
                    onPressed: _resetCompare,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('❗'),
                        selected: _levels.contains(MistakeSeverity.high),
                        onSelected: (_) => _toggleLevel(MistakeSeverity.high),
                      ),
                      ChoiceChip(
                        label: const Text('⚠️'),
                        selected: _levels.contains(MistakeSeverity.medium),
                        onSelected: (_) => _toggleLevel(MistakeSeverity.medium),
                      ),
                      ChoiceChip(
                        label: const Text('ℹ️'),
                        selected: _levels.contains(MistakeSeverity.low),
                        onSelected: (_) => _toggleLevel(MistakeSeverity.low),
                      ),
                      if (_levels.length != MistakeSeverity.values.length)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: Colors.white70,
                          tooltip: 'Очистить',
                          onPressed: _resetLevels,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 36,
            child: Consumer<TagService>(
              builder: (context, service, _) => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final t in tags)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(t),
                        selected: _activeTags.contains(t),
                        selectedColor: colorFromHex(service.colorOf(t)),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _activeTags.add(t);
                            } else {
                              _activeTags.remove(t);
                            }
                          });
                          _saveTags();
                        },
                      ),
                    ),
                  if (_activeTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.white70,
                        tooltip: 'Очистить',
                        onPressed: () {
                          setState(() => _activeTags.clear());
                          _saveTags();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: SwitchListTile(
              title: const Text('Сравнить с предыдущим периодом'),
              value: _comparePrevious,
              onChanged: _toggleComparePrevious,
              activeColor: Colors.orange,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text('Период',
                    style: TextStyle(color: Colors.white)),
                const Spacer(),
                ToggleButtons(
                  isSelected: [
                    _chartMode == _ChartMode.daily,
                    _chartMode == _ChartMode.weekly,
                  ],
                  onPressed: (i) => _setChartMode(_ChartMode.values[i]),
                  borderRadius: BorderRadius.circular(4),
                  selectedColor: Colors.white,
                  fillColor: Colors.blueGrey,
                  color: Colors.white70,
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('День'),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('Неделя'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverToBoxAdapter(
            child: RepaintBoundary(
              key: _chartKey,
              child: SizedBox(
                height: 216,
                child: Column(
                  children: [
                    _buildLegend(chartColors, chartCounts.length > 1, true),
                    const SizedBox(height: 8),
                    Expanded(
                      child: MistakeTrendChart(
                        counts: chartCounts,
                        colors: chartColors,
                        onDayTap: _openDay,
                        highlights: sharedPeaks,
                        showLegend: false,
                        mode: MistakeTrendMode.values[_chartMode.index],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_compareRange != null && !_comparePrevious)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 216,
                child: Column(
                  children: [
                    _buildLegend(cmpColors, cmpCounts.length > 1, false),
                    const SizedBox(height: 8),
                    Expanded(
                      child: MistakeTrendChart(
                        counts: cmpCounts,
                        colors: cmpColors,
                        highlights: sharedPeaks,
                        showLegend: false,
                        mode: MistakeTrendMode.values[_chartMode.index],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (diffs.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final d in diffs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(d.key,
                              style: const TextStyle(color: Colors.white)),
                          Text(
                            '${d.value >= 0 ? '+' : ''}${d.value.toStringAsFixed(0)}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (entries.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: MistakeEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final e = entries[index];
                  final severity = context
                      .read<EvaluationExecutorService>()
                      .classifySeverity(e.value);
                  return ListTile(
                    title: Text(e.key,
                        style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: severity.tooltip,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: severity.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(e.value.toString(),
                            style: const TextStyle(color: Colors.white)),
                        IconButton(
                          icon: const Icon(Icons.cleaning_services,
                              size: 20, color: Colors.white54),
                          tooltip: 'Игнорировать',
                          onPressed: () => context
                              .read<IgnoredMistakeService>()
                              .ignore('tag:${e.key}'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => TagInsightScreen(tag: e.key)),
                      );
                    },
                  );
                },
                childCount: entries.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _TagMistakeHandsScreen extends StatelessWidget {
  final String tag;
  final String dateFilter;
  final DateTimeRange? dateRange;
  const _TagMistakeHandsScreen(
      {required this.tag, required this.dateFilter});

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final hands = [
      for (final h in allHands)
        if ((dateFilter == 'Все' ||
                (dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
                (dateFilter == '7 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
                (dateFilter == '30 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 30))))) &&
            (dateRange == null ||
                (!h.date.isBefore(dateRange!.start) &&
                    !h.date.isAfter(dateRange!.end))))
          h
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: SavedHandListView(
        hands: hands,
        tags: [tag],
        initialAccuracy: 'errors',
        filterKey: tag,
        title: 'Ошибки: $tag',
        onTap: (hand) {
          showSavedHandViewerDialog(context, hand);
        },
      ),
    );
  }
}

class _DailySeverityHandsScreen extends StatelessWidget {
  final DateTime day;
  final String dateFilter;
  final DateTimeRange? dateRange;
  final Set<String>? tags;
  final Set<MistakeSeverity> levels;

  const _DailySeverityHandsScreen({
    required this.day,
    required this.dateFilter,
    this.dateRange,
    this.tags,
    required this.levels,
  });

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final filtered = [
      for (final h in allHands)
        if ((dateFilter == 'Все' ||
                (dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
                (dateFilter == '7 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
                (dateFilter == '30 дней' &&
                    h.date.isAfter(now.subtract(const Duration(days: 30))))) &&
            (dateRange == null ||
                (!h.date.isBefore(dateRange!.start) &&
                    !h.date.isAfter(dateRange!.end))) &&
            _sameDay(h.date, day))
          h
    ];
    final service = context.read<EvaluationExecutorService>();
    final ignored = context.read<IgnoredMistakeService>().ignored;
    final summary = service.summarizeHands(filtered);
    final baseEntries = summary.mistakeTagFrequencies.entries
        .where((e) => !ignored.contains('tag:${e.key}'))
        .toList();
    final visibleTags = tags != null && tags!.isNotEmpty
        ? tags!
        : {
            for (final e in baseEntries)
              if (levels.contains(service.classifySeverity(e.value))) e.key
          };
    final hands = [
      for (final h in filtered)
        if (h.expectedAction != null &&
            h.gtoAction != null &&
            h.expectedAction!.trim().toLowerCase() !=
                h.gtoAction!.trim().toLowerCase() &&
            (visibleTags.isEmpty || h.tags.any(visibleTags.contains)))
          h
    ];
    final severityMap = {
      for (final e in baseEntries)
        if (visibleTags.isEmpty || visibleTags.contains(e.key))
          e.key: service.classifySeverity(e.value)
    };
    final grouped = {
      MistakeSeverity.high: <SavedHand>[],
      MistakeSeverity.medium: <SavedHand>[],
      MistakeSeverity.low: <SavedHand>[],
    };
    for (final h in hands) {
      MistakeSeverity? level;
      for (final t in h.tags) {
        final s = severityMap[t];
        if (s == null) continue;
        if (level == null || s.index < level.index) level = s;
      }
      if (level != null) grouped[level]!.add(h);
    }

    Widget section(MistakeSeverity s, String label, List<SavedHand> data) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(12),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            textColor: Colors.white,
            collapsedTextColor: Colors.white,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label),
                Text('${data.length}',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
            children: [
              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Нет ошибок',
                      style: TextStyle(color: Colors.white70)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final hand = data[index];
                    return SavedHandTile(
                      hand: hand,
                      onTap: () {
                        showSavedHandViewerDialog(context, hand);
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(formatLongDate(day)),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          section(
              MistakeSeverity.high, 'High ❗', grouped[MistakeSeverity.high]!),
          section(MistakeSeverity.medium, 'Medium ⚠️',
              grouped[MistakeSeverity.medium]!),
          section(MistakeSeverity.low, 'Low ℹ️', grouped[MistakeSeverity.low]!),
        ],
      ),
    );
  }
}
