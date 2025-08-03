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
import '../models/mistake_severity.dart';
import '../models/mistake_sort_option.dart';
import '../theme/app_colors.dart';
import '../services/ignored_mistake_service.dart';
import '../widgets/saved_hand_list_view.dart';
import '../widgets/mistake_summary_section.dart';
import '../widgets/mistake_empty_state.dart';
import '../widgets/saved_hand_viewer_dialog.dart';
import '../widgets/sync_status_widget.dart';
import '../constants/app_constants.dart';

/// Displays a list of hero positions sorted by mistake count.
///
/// Information is pulled from [EvaluationExecutorService.summarizeHands]. Each
/// tile shows how many errors were made from that position. Selecting a
/// position opens a filtered [SavedHandListView] showing only the mistaken
/// hands for the chosen position. A share button exports the table to PDF
/// for convenient review outside the app.
class PositionMistakeOverviewScreen extends StatefulWidget {
  final String dateFilter;
  const PositionMistakeOverviewScreen({super.key, required this.dateFilter});

  @override
  State<PositionMistakeOverviewScreen> createState() => _PositionMistakeOverviewScreenState();
}

class _PositionMistakeOverviewScreenState extends State<PositionMistakeOverviewScreen> {
  MistakeSortOption _sort = MistakeSortOption.count;

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _exportPdf(
      BuildContext context, SummaryResult summary, List<MapEntry<String, int>> entries) async {

    final regularFont = await pw.PdfGoogleFonts.robotoRegular();
    final boldFont = await pw.PdfGoogleFonts.robotoBold();

    final pdf = pw.Document();
    final date = formatDateTime(DateTime.now());

    final service = context.read<EvaluationExecutorService>();
    final rows = [
      for (final e in entries)
        [e.key, e.value.toString(), service.classifySeverity(e.value).label]
    ];

    if (entries.isEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) => [
            pw.Text('Ошибки по позициям',
                style: pw.TextStyle(font: boldFont, fontSize: 24)),
            pw.SizedBox(height: 8),
            pw.Text(date, style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 16),
            pw.Text('Ошибок не найдено за выбранный период.',
                style: pw.TextStyle(font: regularFont)),
          ],
        ),
      );
    } else {
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
            pw.Text('Ошибки: $mistakes',
                style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 4),
            pw.Text('Средняя точность: ${accuracy.toStringAsFixed(1)}%',
                style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 4),
            pw.Text('Доля рук с ошибками: ${mistakePercent.toStringAsFixed(1)}%',
                style: pw.TextStyle(font: regularFont)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: const ['Позиция', 'Ошибки', 'Уровень'],
              data: rows,
            ),
          ],
        ),
      );
    }

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
        if (widget.dateFilter == 'Все' ||
            (widget.dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
            (widget.dateFilter == '7 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
            (widget.dateFilter == '30 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 30)))))
          h
    ];
    final summary =
        context.read<EvaluationExecutorService>().summarizeHands(hands);
    final ignored = context.watch<IgnoredMistakeService>().ignored;
    final service = context.read<EvaluationExecutorService>();
    final entries = summary.positionMistakeFrequencies.entries
        .where((e) => !ignored.contains('position:${e.key}'))
        .toList();

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
    } else {
      entries.sort((a, b) => b.value.compareTo(a.value));
    }

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
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          sliver: SliverToBoxAdapter(
            child: MistakeSummarySection(summary: summary),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.defaultPadding,
            0,
            AppConstants.defaultPadding,
            AppConstants.defaultPadding / 2,
          ),
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
        if (entries.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: MistakeEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
                              .ignore('position:${e.key}'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => _PositionMistakeHandsScreen(
                            position: e.key,
                            dateFilter: widget.dateFilter,
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
        actions: [SyncStatusIcon.of(context)],
      ),
      body: SavedHandListView(
        hands: hands,
        positions: [position],
        initialAccuracy: 'errors',
        filterKey: position,
        title: 'Ошибки: $position',
        onTap: (hand) {
          showSavedHandViewerDialog(context, hand);
        },
      ),
    );
  }
}
