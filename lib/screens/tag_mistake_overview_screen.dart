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
import '../services/tag_service.dart';
import '../helpers/color_utils.dart';
import '../widgets/saved_hand_list_view.dart';
import '../widgets/mistake_summary_section.dart';
import '../widgets/mistake_empty_state.dart';
import 'hand_history_review_screen.dart';

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
  State<TagMistakeOverviewScreen> createState() => _TagMistakeOverviewScreenState();
}

class _TagMistakeOverviewScreenState extends State<TagMistakeOverviewScreen> {
  MistakeSortOption _sort = MistakeSortOption.count;
  String? _activeTag;
  DateTimeRange? _range;
  final Set<MistakeSeverity> _levels =
      {MistakeSeverity.high, MistakeSeverity.medium, MistakeSeverity.low};

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
    if (picked != null) setState(() => _range = picked);
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
  }

  void _resetLevels() {
    setState(() {
      _levels
        ..clear()
        ..addAll(MistakeSeverity.values);
    });
  }

  Future<void> _exportPdf(BuildContext context, SummaryResult summary,
      List<MapEntry<String, int>> entries) async {

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
            pw.Text('Ошибки по тегам',
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
            pw.Text('Ошибки по тегам',
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
              headers: const ['Тег', 'Ошибки', 'Уровень'],
              data: rows,
            ),
          ],
        ),
      );
    }

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/tag_summary.pdf');
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
    if (_activeTag != null) {
      entries.removeWhere((e) => e.key != _activeTag);
    }
    entries.removeWhere(
        (e) => !_levels.contains(service.classifySeverity(e.value)));

    int _score(MapEntry<String, int> e) {
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
        final cmp = _score(b).compareTo(_score(a));
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
                    icon: const Icon(Icons.close, size: 18, color: Colors.white70),
                    onPressed: () => setState(() => _range = null),
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
                      child: ChoiceChip(
                        label: Text(t),
                        selected: _activeTag == t,
                        selectedColor: colorFromHex(service.colorOf(t)),
                        onSelected: (_) => setState(() =>
                            _activeTag = _activeTag == t ? null : t),
                      ),
                    ),
                  if (_activeTag != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.white70,
                        tooltip: 'Очистить',
                        onPressed: () => setState(() => _activeTag = null),
                      ),
                    ),
                ],
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
                          builder: (_) => _TagMistakeHandsScreen(
                            tag: e.key,
                            dateFilter: widget.dateFilter,
                            dateRange: _range,
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

class _TagMistakeHandsScreen extends StatelessWidget {
  final String tag;
  final String dateFilter;
  final DateTimeRange? dateRange;
  const _TagMistakeHandsScreen({required this.tag, required this.dateFilter, this.dateRange});

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
                    !h.date.isAfter(dateRange!.end)))
        h
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
        centerTitle: true,
      ),
      body: SavedHandListView(
        hands: hands,
        tags: [tag],
        initialAccuracy: 'errors',
        filterKey: tag,
        title: 'Ошибки: $tag',
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
