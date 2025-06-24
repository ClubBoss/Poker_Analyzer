import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/summary_result.dart';
import 'dart:io';

import '../helpers/date_utils.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/evaluation_executor_service.dart';
import '../widgets/saved_hand_list_view.dart';
import '../widgets/mistake_summary_section.dart';
import 'hand_history_review_screen.dart';

/// Displays a list of hero positions sorted by mistake count.
///
/// Information is pulled from [EvaluationExecutorService.summarizeHands]. Each
/// tile shows how many errors were made from that position. Selecting a
/// position opens a filtered [SavedHandListView] showing only the mistaken
/// hands for the chosen position. A share button exports the table to PDF
/// for convenient review outside the app.
class PositionMistakeOverviewScreen extends StatelessWidget {
  final String dateFilter;
  const PositionMistakeOverviewScreen({super.key, required this.dateFilter});

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _exportPdf(
      BuildContext context, SummaryResult summary, List<MapEntry<String, int>> entries) async {
    if (entries.isEmpty) return;

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final date = formatDateTime(DateTime.now());
    final mistakes = summary.incorrect;
    final total = summary.totalHands;
    final accuracy = summary.accuracy;
    final mistakePercent = total > 0 ? mistakes / total * 100 : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text('Ошибки по позициям',
              style: pw.TextStyle(font: boldFont, fontSize: 24)),
          pw.SizedBox(height: 8),
          pw.Text(date, style: pw.TextStyle(font: regularFont)),
          pw.SizedBox(height: 16),
            pw.Text("Ошибки: $mistakes", style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 4),
            pw.Text("Средняя точность: ${accuracy.toStringAsFixed(1)}%", style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 4),
            pw.Text("Доля рук с ошибками: ${mistakePercent.toStringAsFixed(1)}%", style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['Позиция', 'Ошибки'],
            data: [for (final e in entries) [e.key, e.value.toString()]],
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/position_summary.pdf');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(file.path)], text: 'position_summary.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final hands = [
      for (final h in allHands)
        if (dateFilter == 'Все' ||
            (dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
            (dateFilter == '7 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
            (dateFilter == '30 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 30)))))
          h
    ];
    final summary =
        context.read<EvaluationExecutorService>().summarizeHands(hands);
    final entries = summary.positionMistakeFrequencies.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          title: const Text('Ошибки по позициям'),
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
        if (entries.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'Ошибок нет',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final e = entries[index];
                  return ListTile(
                    title: Text(e.key, style: const TextStyle(color: Colors.white)),
                    trailing: Text(e.value.toString(),
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _PositionMistakeHandsScreen(
                            position: e.key,
                            dateFilter: dateFilter,
                          ),
                        ),
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

class _PositionMistakeHandsScreen extends StatelessWidget {
  final String position;
  final String dateFilter;
  const _PositionMistakeHandsScreen({required this.position, required this.dateFilter});

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final allHands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final hands = [
      for (final h in allHands)
        if (dateFilter == 'Все' ||
            (dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
            (dateFilter == '7 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
            (dateFilter == '30 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 30)))))
          h
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(position),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: hands,
        positions: [position],
        accuracy: 'errors',
        title: 'Ошибки: $position',
        onTap: (hand) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HandHistoryReviewScreen(hand: hand),
            ),
          );
        },
      ),
    );
  }
}
