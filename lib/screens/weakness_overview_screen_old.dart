import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_stats_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../services/training_stats_service.dart';
import '../services/user_preferences_service.dart';
import '../helpers/date_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import '../helpers/category_translations.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';
import 'mistake_review_screen.dart';
import 'mistake_detail_screen.dart';
import 'corrected_mistake_history_screen.dart';
import 'category_recovery_screen.dart';
import 'category_analytics_screen.dart';

class WeaknessOverviewScreen extends StatefulWidget {
  static const route = '/weakness_overview';
  final bool autoExport;
  const WeaknessOverviewScreen({super.key, this.autoExport = false});

  @override
  State<WeaknessOverviewScreen> createState() => _WeaknessOverviewScreenState();
}

class _WeaknessOverviewScreenState extends State<WeaknessOverviewScreen> {
  final ScrollController _ctrl = ScrollController();
  final _keys = <GlobalKey>[];
  int? _highlight;
  DateTimeRange? _range;
  int _limit = 5;
  @override
  void initState() {
    super.initState();
    final prefs = context.read<UserPreferencesService>();
    _range = prefs.weaknessRange;
    _limit = prefs.weaknessCategoryCount;
    final list = _entries(context);
    if (list.isNotEmpty) {
      double max = -1;
      int idx = 0;
      for (var i = 0; i < list.length; i++) {
        final v = list[i].value;
        final u = v.evLoss - v.recovered;
        if (u > max) {
          max = u;
          idx = i;
        }
      }
      _highlight = idx;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.autoExport) {
        await _exportPdf(context);
        if (mounted) Navigator.pop(context);
      } else {
        _scrollToIndex();
      }
    });
  }

  List<MapEntry<String, _CatStat>> _entries(BuildContext context) {
    final allHands = context.read<SavedHandManagerService>().hands;
    final hands = _range == null
        ? allHands
        : [
            for (final h in allHands)
              if (!h.savedAt.isBefore(_range!.start) &&
                  !h.savedAt.isAfter(_range!.end))
                h
          ];
    final stats = <String, _CatStat>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      final s = stats.putIfAbsent(cat, () => _CatStat());
      s.count += 1;
      s.evLoss += h.evLoss ?? 0;
      if (h.corrected) {
        s.corrected += 1;
        s.recovered += h.evLossRecovered ?? 0;
      } else {
        s.uncorrected += h.evLoss ?? 0;
      }
    }
    final list = stats.entries.toList()
      ..sort((a, b) {
        final at = a.value.evLoss;
        final bt = b.value.evLoss;
        if (at == 0 && bt == 0) return 0;
        if (at == 0) return 1;
        if (bt == 0) return -1;
        final ar = 1 - (a.value.recovered / at);
        final br = 1 - (b.value.recovered / bt);
        final cmp = br.compareTo(ar);
        return cmp == 0 ? bt.compareTo(at) : cmp;
      });
    return list.take(_limit).toList();
  }

  void _scrollToIndex() {
    if (_highlight == null) return;
    if (_highlight! >= _keys.length) return;
    final ctx = _keys[_highlight!].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
    }
  }

  String get _rangeLabel {
    if (_range == null) return 'Период';
    final start = formatDate(_range!.start);
    final end = formatDate(_range!.end);
    return start == end ? start : '$start – $end';
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
      setState(() => _range = picked);
      context.read<UserPreferencesService>().setWeaknessRange(picked);
    }
  }

  void _setLimit(int value) {
    setState(() => _limit = value);
    context.read<UserPreferencesService>().setWeaknessCategoryCount(value);
  }

  Future<void> _exportPdf(BuildContext context) async {
    final catProgress = context.read<TrainingSessionService>().getCategoryStats();
    final entries = _entries(context);

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (c) {
          return [
            pw.Text('Слабые места',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            for (final e in entries)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    translateCategory(e.key).isEmpty
                        ? 'Без категории'
                        : translateCategory(e.key),
                    style: pw.TextStyle(font: boldFont, fontSize: 16),
                  ),
                  pw.Text(
                    '${e.value.count} ошибок • -${e.value.evLoss.toStringAsFixed(2)} EV',
                    style: pw.TextStyle(font: regularFont, fontSize: 12),
                  ),
                  if (e.value.count > 0)
                    pw.Text(
                      'Исправлено: ${e.value.corrected} из ${e.value.count} (${(e.value.corrected * 100 / e.value.count).round()}%) • +${e.value.recovered.toStringAsFixed(2)} EV',
                      style: pw.TextStyle(font: regularFont, fontSize: 11),
                    ),
                  if (catProgress[e.key] != null &&
                      catProgress[e.key]!.played > 0)
                    pw.Text(
                      'Тренировок: ${catProgress[e.key]!.played} • ${(catProgress[e.key]!.correct * 100 / catProgress[e.key]!.played).round()}% верно • +${catProgress[e.key]!.evSaved.toStringAsFixed(2)} EV',
                      style: pw.TextStyle(font: regularFont, fontSize: 11),
                    ),
                  pw.SizedBox(height: 12),
                ],
              ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/weakness_report.pdf');
    await file.writeAsBytes(bytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Файл сохранён: weakness_report.pdf'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () => OpenFilex.open(file.path),
          ),
        ),
      );
    }
  }

  Widget _recentFixes(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final recent = [for (final h in hands) if (h.corrected) h]
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    if (recent.isEmpty) return const SizedBox.shrink();
    final list = recent.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Последние исправленные ошибки',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        for (final h in list)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MistakeDetailScreen(hand: h),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.heroPosition,
                            style: const TextStyle(color: Colors.white)),
                        if (h.evLossRecovered != null)
                          Text(
                            '+${h.evLossRecovered!.toStringAsFixed(2)} EV',
                            style: const TextStyle(
                                color: Colors.greenAccent, fontSize: 12),
                          ),
                        if (h.tags.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              spacing: 4,
                              children: [
                                for (final t in h.tags)
                                  Chip(
                                    label: Text(t),
                                    backgroundColor: const Color(0xFF3A3B3E),
                                    labelStyle:
                                        const TextStyle(color: Colors.white),
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CorrectedMistakeHistoryScreen(),
              ),
            );
          },
          child: const Text('Показать всё'),
        ),
      ],
    );
  }

  Widget _historyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CategoryRecoveryScreen()),
          );
        },
        icon: const Icon(Icons.category),
        label: const Text('История устранённых слабостей'),
      ),
    );
  }

  Widget _analyticsButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TextButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CategoryAnalyticsScreen()),
          );
        },
        icon: const Icon(Icons.show_chart),
        label: const Text('Динамика категории'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final catProgress =
        context.watch<TrainingSessionService>().getCategoryStats();
    final stats = <String, _CatStat>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      final s = stats.putIfAbsent(cat, () => _CatStat());
      s.count += 1;
      s.evLoss += h.evLoss ?? 0;
      if (h.corrected) {
        s.corrected += 1;
        s.recovered += h.evLossRecovered ?? 0;
      } else {
        s.uncorrected += h.evLoss ?? 0;
      }
    }
    final entries = stats.entries.toList()
      ..sort((a, b) {
        final at = a.value.evLoss;
        final bt = b.value.evLoss;
        if (at == 0 && bt == 0) return 0;
        if (at == 0) return 1;
        if (bt == 0) return -1;
        final ar = 1 - (a.value.recovered / at);
        final br = 1 - (b.value.recovered / bt);
        final cmp = br.compareTo(ar);
        return cmp == 0 ? bt.compareTo(at) : cmp;
      });
    if (_keys.length != entries.length) {
      _keys
        ..clear()
        ..addAll(List.generate(entries.length, (_) => GlobalKey()));
    }
    double evLossTotal = 0;
    double evLossRecovered = 0;
    for (final s in stats.values) {
      evLossTotal += s.evLoss;
      evLossRecovered += s.recovered;
    }
    MapEntry<String, _CatStat>? mainError;
    double maxEvLoss = -1;
    for (final e in entries) {
      if (e.value.evLoss > maxEvLoss) {
        maxEvLoss = e.value.evLoss;
        mainError = e;
      }
    }
    MapEntry<String, _CatStat>? weakest;
    double maxUnrec = -1;
    for (final e in entries) {
      final loss = e.value.evLoss - e.value.recovered;
      if (loss > maxUnrec) {
        maxUnrec = loss;
        weakest = e;
      }
    }
    MapEntry<String, _CatStat>? drillCat;
    double drillLoss = -1;
    for (final e in entries) {
      if (e.value.uncorrected > drillLoss) {
        drillLoss = e.value.uncorrected;
        drillCat = e;
      }
    }
    final progress =
        evLossTotal > 0 ? (evLossRecovered / evLossTotal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();
    final showTopDrill = entries.length >= 3;
    final topList = entries
        .toList()
      ..sort((a, b) =>
          (b.value.evLoss - b.value.recovered)
              .compareTo(a.value.evLoss - a.value.recovered));
    final topCats = topList.take(3).toList();
    final topLoss = topCats.fold<double>(
        0, (p, e) => p + e.value.evLoss - e.value.recovered);
    final topNames = [
      for (final e in topCats)
        translateCategory(e.key).isEmpty
            ? 'Без категории'
            : translateCategory(e.key)
    ].join(', ');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Слабые места'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Экспорт',
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => context.read<TrainingStatsService>().shareProgress(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (mainError != null && maxEvLoss > 0)
              Card(
                color: AppColors.cardBackground,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Главная ошибка',
                                style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              translateCategory(mainError.key).isEmpty
                                  ? 'Без категории'
                                  : translateCategory(mainError.key),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '-${maxEvLoss.toStringAsFixed(2)} EV',
                        style: const TextStyle(color: Colors.redAccent),
                      )
                    ],
                  ),
                ),
              ),
            if (evLossTotal > 0) ...[
              const Text('Слабые места исправлены',
                  style: TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text('Исправлено $percent% EV',
                  style:
                      const TextStyle(color: Colors.greenAccent, fontSize: 12)),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                TextButton(
                  onPressed: _pickRange,
                  child: Text(_rangeLabel),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _limit,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Colors.grey[900],
                  items: [3, 5, 10]
                      .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _setLimit(v);
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                controller: _ctrl,
                itemCount: entries.length + 3,
                itemBuilder: (context, index) {
                  if (index == entries.length) {
                    return _analyticsButton(context);
                  }
                  if (index == entries.length + 1) {
                    return _historyButton(context);
                  }
                  if (index == entries.length + 2) {
                    return _recentFixes(context);
                  }
                  final e = entries[index];
          final name = translateCategory(e.key);
          return Container(
            key: _keys[index],
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index == _highlight ? Colors.red.shade900 : Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
              border: index == _highlight ? Border.all(color: Colors.red) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'Без категории' : name,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        '${e.value.count} ошибок • -${e.value.evLoss.toStringAsFixed(2)} EV',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      if (e.value.count > 0)
                        Text(
                          'Исправлено: ${e.value.corrected} из ${e.value.count} (${(e.value.corrected * 100 / e.value.count).round()}%) • +${e.value.recovered.toStringAsFixed(2)} EV',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.greenAccent),
                        ),
                      if (catProgress[e.key] != null && catProgress[e.key]!.played > 0)
                        Text(
                          'Тренировок: ${catProgress[e.key]!.played} • ${((catProgress[e.key]!.correct * 100 / catProgress[e.key]!.played).round())}% верно • +${catProgress[e.key]!.evSaved.toStringAsFixed(2)} EV',
                          style: const TextStyle(fontSize: 11, color: Colors.blueAccent),
                        ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final tpl = await TrainingPackService.createDrillFromCategory(
                                context, e.key);
                        if (tpl == null) return;
                        await context
                            .read<TrainingSessionService>()
                            .startSession(tpl);
                        if (context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TrainingSessionScreen()),
                          );
                        }
                      },
                      child: const Text('Тренироваться'),
                    ),
                        TextButton(
                          onPressed: () {
                            final manager = context.read<SavedHandManagerService>();
                            final stats =
                                context.read<SavedHandStatsService>();
                            final list = stats.filterByCategory(e.key);
                        if (list.isEmpty) return;
                        final tpl = manager.createPack('Ошибки', list);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MistakeReviewScreen(template: tpl)),
                        );
                      },
                      child: const Text('Все ошибки этой категории'),
                        ),
                      ],
                    )
                  ],
                ),
                if (catProgress[e.key] != null && catProgress[e.key]!.played > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      height: 120,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          sections: [
                            PieChartSectionData(
                              value: catProgress[e.key]!.correct.toDouble(),
                              color: Colors.green,
                              title: '',
                            ),
                            PieChartSectionData(
                              value: (catProgress[e.key]!.played - catProgress[e.key]!.correct).toDouble(),
                              color: Colors.red,
                              title: '',
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            ),
          );
        },
      ),
      ),
      bottomNavigationBar: (drillCat != null && drillLoss > 0) ||
              (showTopDrill && topLoss > 0)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (drillCat != null && drillLoss > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                      'Тренировка по самой слабой категории',
                                      style: TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 4),
                                  Text(
                                    translateCategory(drillCat!.key).isEmpty
                                        ? 'Без категории'
                                        : translateCategory(drillCat!.key),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '-${drillLoss.toStringAsFixed(2)} EV',
                                    style:
                                        const TextStyle(color: Colors.redAccent),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final tpl =
                                    await TrainingPackService.createDrillFromCategory(
                                        context, drillCat!.key);
                                if (tpl == null) return;
                                await context
                                    .read<TrainingSessionService>()
                                    .startSession(tpl);
                                if (context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const TrainingSessionScreen()),
                                  );
                                }
                              },
                              child: const Text('Начать'),
                            )
                          ],
                        ),
                      ),
                    if (showTopDrill && topLoss > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[850],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Drill из топ-3 категорий',
                                        style:
                                            TextStyle(color: Colors.white70)),
                                    const SizedBox(height: 4),
                                    Text(topNames,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('-${topLoss.toStringAsFixed(2)} EV',
                                        style: const TextStyle(
                                            color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final tpl =
                                      await TrainingPackService.createDrillFromTopCategories(
                                          context);
                                  if (tpl == null) return;
                                  await context
                                      .read<TrainingSessionService>()
                                      .startSession(tpl);
                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const TrainingSessionScreen()),
                                    );
                                  }
                                },
                                child: const Text('Начать'),
                              )
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _CatStat {
  int count = 0;
  double evLoss = 0;
  int corrected = 0;
  double recovered = 0;
  double uncorrected = 0;
}
