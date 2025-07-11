import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../helpers/category_translations.dart';
import 'training_session_screen.dart';
import 'mistake_review_screen.dart';
import 'mistake_detail_screen.dart';

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
  @override
  void initState() {
    super.initState();
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
    final hands = context.read<SavedHandManagerService>().hands;
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
    return list;
  }

  void _scrollToIndex() {
    if (_highlight == null) return;
    if (_highlight! >= _keys.length) return;
    final ctx = _keys[_highlight!].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300));
    }
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
      ],
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
    MapEntry<String, _CatStat>? weakest;
    double maxUnrec = -1;
    for (final e in entries) {
      final loss = e.value.evLoss - e.value.recovered;
      if (loss > maxUnrec) {
        maxUnrec = loss;
        weakest = e;
      }
    }
    final progress =
        evLossTotal > 0 ? (evLossRecovered / evLossTotal).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();
    final showTopDrill = entries.length >= 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Слабые места'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Экспорт',
            onPressed: () => _exportPdf(context),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (showTopDrill)
              ElevatedButton.icon(
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
                          builder: (_) => const TrainingSessionScreen()),
                    );
                  }
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Drill из топ-3 категорий'),
              ),
            if (showTopDrill) const SizedBox(height: 16),
            if (weakest != null && maxUnrec > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
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
                          const Text('Ваша слабейшая категория',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            translateCategory(weakest!.key).isEmpty
                                ? 'Без категории'
                                : translateCategory(weakest!.key),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '-${maxUnrec.toStringAsFixed(2)} EV',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final tpl = await TrainingPackService.createDrillFromCategory(
                            context, weakest!.key);
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
                      child: const Text('Drill по ней'),
                    )
                  ],
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
            Expanded(
              child: ListView.builder(
                controller: _ctrl,
                itemCount: entries.length + 1,
                itemBuilder: (context, index) {
                  if (index == entries.length) {
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
              border: index == _highlight
                  ? Border.all(color: Colors.red)
                  : null,
            ),
            child: Row(
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
                        final list = manager.filterByCategory(e.key);
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
          );
        },
      ),
    );
  }
}

class _CatStat {
  int count = 0;
  double evLoss = 0;
  int corrected = 0;
  double recovered = 0;
}
