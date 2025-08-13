import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/daily_ev_icm_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../services/training_stats_service.dart';
import '../services/daily_target_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/lesson_streak_badge_tooltip_widget.dart';
import '../services/png_exporter.dart';
import '../helpers/date_utils.dart';
import '../utils/responsive.dart';
import 'mistake_review_screen.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final _boundaryKey = GlobalKey();

  Future<void> _share() async {
    final boundary = _boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;
    final bytes = await PngExporter.captureBoundary(boundary);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/dashboard_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _exportCsv() async {
    final service = context.read<TrainingStatsService>();
    final sessions = {
      for (final e in service.sessionsDaily(30)) e.key: e.value
    };
    final hands = {for (final e in service.handsDaily(30)) e.key: e.value};
    final mistakes = {
      for (final e in service.mistakesDaily(30)) e.key: e.value
    };
    final dates = {
      ...sessions.keys,
      ...hands.keys,
      ...mistakes.keys,
    }.toList()
      ..sort();
    final rows = <List<dynamic>>[
      ['Date', 'Sessions', 'Hands', 'Mistakes']
    ];
    for (final d in dates) {
      rows.add(
          [formatDate(d), sessions[d] ?? 0, hands[d] ?? 0, mistakes[d] ?? 0]);
    }
    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final fileName = 'daily_stats_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvStr, encoding: utf8);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Файл сохранён: $fileName')));
    }
  }

  Future<void> _exportPdf() async {
    final stats = context.read<TrainingStatsService>();
    final handsService = context.read<SavedHandManagerService>();
    final sessionsTotal =
        stats.sessionsDaily(30).fold<int>(0, (a, e) => a + e.value);
    final handsTotal = stats.handsDaily(30).fold<int>(0, (a, e) => a + e.value);
    final mistakesTotal =
        stats.mistakesDaily(30).fold<int>(0, (a, e) => a + e.value);

    final chartBytes = await PngExporter.exportWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: stats),
          ChangeNotifierProvider.value(value: handsService),
        ],
        child: const DailyEvIcmChart(),
      ),
    );

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Progress Dashboard',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Sessions: $sessionsTotal',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Hands: $handsTotal',
                style: pw.TextStyle(font: regularFont)),
            pw.Text('Mistakes: $mistakesTotal',
                style: pw.TextStyle(font: regularFont)),
            if (chartBytes != null) ...[
              pw.SizedBox(height: 16),
              pw.Image(pw.MemoryImage(chartBytes)),
            ],
          ],
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'dashboard_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<TrainingStatsService>();
    final target = context.watch<DailyTargetService>().target;
    final hands = stats.handsPerDay;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 29));
    final days = [for (var i = 0; i < 30; i++) start.add(Duration(days: i))];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        centerTitle: true,
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LessonStreakBadgeTooltipWidget(dense: true),
          ),
          IconButton(onPressed: _share, icon: const Icon(Icons.share)),
          IconButton(onPressed: _exportCsv, icon: const Icon(Icons.download)),
          IconButton(
              onPressed: _exportPdf, icon: const Icon(Icons.picture_as_pdf)),
          SyncStatusIcon.of(context)
        ],
      ),
      body: RepaintBoundary(
        key: _boundaryKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLandscape(context)
                    ? (isCompactWidth(context) ? 6 : 10)
                    : (isCompactWidth(context) ? 4 : 7),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final d = days[index];
                final count = hands[d] ?? 0;
                final met = count >= target;
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: met ? Colors.greenAccent : Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${d.day}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                      Text('$count',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10))
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const DailyEvIcmChart(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MistakeReviewScreen()),
                );
              },
              child: const Text('Повтор ошибок'),
            ),
          ],
        ),
      ),
    );
  }
}
