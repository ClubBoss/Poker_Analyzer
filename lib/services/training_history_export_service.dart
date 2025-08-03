import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/date_utils.dart';
import '../models/training_result.dart';

class TrainingHistoryPrefs {
  final int sortIndex;
  final int ratingIndex;
  final int accuracyRangeIndex;
  final List<String> tags;
  final List<String> tagColors;
  final bool? showCharts;
  final bool? showAvgChart;
  final bool? showDistribution;
  final bool? showTrendChart;
  final bool hideEmptyTags;
  final bool sortByTag;
  final int chartModeIndex;
  final int tagCountIndex;
  final int weekdayIndex;
  final int lengthIndex;
  final bool includeChartInPdf;
  final bool exportTags3Only;
  final bool exportNotesOnly;
  final int? dateFromMillis;
  final int? dateToMillis;

  TrainingHistoryPrefs({
    required this.sortIndex,
    required this.ratingIndex,
    required this.accuracyRangeIndex,
    required this.tags,
    required this.tagColors,
    required this.showCharts,
    required this.showAvgChart,
    required this.showDistribution,
    required this.showTrendChart,
    required this.hideEmptyTags,
    required this.sortByTag,
    required this.chartModeIndex,
    required this.tagCountIndex,
    required this.weekdayIndex,
    required this.lengthIndex,
    required this.includeChartInPdf,
    required this.exportTags3Only,
    required this.exportNotesOnly,
    required this.dateFromMillis,
    required this.dateToMillis,
  });
}

class TrainingHistoryExportService {
  static const _sortKey = 'training_history_sort';
  static const _ratingKey = 'training_history_rating';
  static const _accuracyRangeKey = 'training_history_accuracy_range';
  static const _tagKey = 'training_history_tag_filter';
  static const _tagColorKey = 'training_history_tag_color_filter';
  static const _showChartsKey = 'training_history_show_charts';
  static const _showAvgChartKey = 'training_history_show_avg_chart';
  static const _showDistributionKey = 'training_history_show_distribution';
  static const _showTrendChartKey = 'training_history_show_trend_chart';
  static const _hideEmptyTagsKey = 'training_history_hide_empty_tags';
  static const _sortByTagKey = 'training_history_sort_by_tag';
  static const _chartModeKey = 'training_history_chart_mode';
  static const _tagCountKey = 'training_history_tag_count';
  static const _weekdayKey = 'training_history_weekday';
  static const _lengthKey = 'training_history_length';
  static const _pdfIncludeChartKey = 'training_history_pdf_include_chart';
  static const _exportTags3OnlyKey = 'training_history_export_tags3_only';
  static const _exportNotesOnlyKey = 'training_history_export_notes_only';
  static const _dateFromKey = 'training_history_date_from';
  static const _dateToKey = 'training_history_date_to';

  Future<TrainingHistoryPrefs> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return TrainingHistoryPrefs(
      sortIndex: prefs.getInt(_sortKey) ?? 0,
      ratingIndex: prefs.getInt(_ratingKey) ?? 0,
      accuracyRangeIndex: prefs.getInt(_accuracyRangeKey) ?? 0,
      tags: prefs.getStringList(_tagKey) ?? const [],
      tagColors: prefs.getStringList(_tagColorKey) ?? const [],
      showCharts: prefs.getBool(_showChartsKey),
      showAvgChart: prefs.getBool(_showAvgChartKey),
      showDistribution: prefs.getBool(_showDistributionKey),
      showTrendChart: prefs.getBool(_showTrendChartKey),
      hideEmptyTags: prefs.getBool(_hideEmptyTagsKey) ?? false,
      sortByTag: prefs.getBool(_sortByTagKey) ?? false,
      chartModeIndex: prefs.getInt(_chartModeKey) ?? 0,
      tagCountIndex: prefs.getInt(_tagCountKey) ?? 0,
      weekdayIndex: prefs.getInt(_weekdayKey) ?? 0,
      lengthIndex: prefs.getInt(_lengthKey) ?? 0,
      includeChartInPdf: prefs.getBool(_pdfIncludeChartKey) ?? true,
      exportTags3Only: prefs.getBool(_exportTags3OnlyKey) ?? false,
      exportNotesOnly: prefs.getBool(_exportNotesOnlyKey) ?? false,
      dateFromMillis: prefs.getInt(_dateFromKey),
      dateToMillis: prefs.getInt(_dateToKey),
    );
  }

  Future<File> exportCsv({
    required List<TrainingResult> sessions,
    required List<String> filters,
  }) async {
    final rows = <List<dynamic>>[];
    if (filters.isNotEmpty) {
      for (final line in filters) {
        rows.add([line]);
      }
      rows.add([]);
    }
    rows.add([
      'Date',
      'Total',
      'Correct',
      'Accuracy',
      'Tags',
      'Comment',
      'Notes'
    ]);
    for (final r in sessions) {
      rows.add([
        formatDateTime(r.date),
        r.total,
        r.correct,
        r.accuracy.toStringAsFixed(1),
        r.tags.join(';'),
        r.comment ?? '',
        r.notes ?? '',
      ]);
    }
    final csvStr = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_history_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvStr, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.csv');
    return file;
  }

  Future<File> exportPdf({
    required List<TrainingResult> sessions,
    required List<TrainingResult> chartData,
    bool includeChart = true,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final table = pw.Table.fromTextArray(
            headers: const [
              'Date',
              'Total',
              'Correct',
              'Accuracy',
              'Tags',
              'Comment',
              'Notes'
            ],
            data: [
              for (final r in sessions)
                [
                  formatDateTime(r.date),
                  r.total,
                  r.correct,
                  r.accuracy.toStringAsFixed(1),
                  r.tags.join(';'),
                  r.comment ?? '',
                  r.notes ?? ''
                ]
            ],
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (includeChart)
                pw.Container(
                  height: 200,
                  child: pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis.fromStrings(
                        [for (final r in chartData) formatDate(r.date)],
                        marginStart: 30,
                      ),
                      yAxis: pw.FixedAxis(
                        [0, 20, 40, 60, 80, 100],
                        divisions: true,
                        marginStart: 30,
                      ),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        drawPoints: false,
                        isCurved: true,
                        data: [
                          for (var i = 0; i < chartData.length; i++)
                            pw.PointChartValue(
                              i.toDouble(),
                              chartData[i].accuracy,
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              if (includeChart) pw.SizedBox(height: 16),
              table,
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_history_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.pdf');
    return file;
  }

  Future<File> exportChartCsv({
    required List<TrainingResult> grouped,
    required String mode,
  }) async {
    final rows = <List<dynamic>>[];
    rows.add(['Date', 'Total', 'Correct', 'Accuracy']);
    for (final r in grouped) {
      rows.add([
        formatDate(r.date),
        r.total,
        r.correct,
        r.accuracy.toStringAsFixed(1),
      ]);
    }
    final csvStr = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'chart_${mode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvStr, encoding: utf8);
    return file;
  }

  Future<File> exportVisibleCsv(List<TrainingResult> sessions) async {
    final rows = <List<dynamic>>[];
    rows.add([
      'Date',
      'Accuracy',
      'Total',
      'Correct',
      'Tags',
      'Comment',
      'Notes'
    ]);
    for (final r in sessions) {
      rows.add([
        formatDateTime(r.date),
        r.accuracy.toStringAsFixed(1),
        r.total,
        r.correct,
        r.tags.join(';'),
        r.comment ?? '',
        r.notes ?? '',
      ]);
    }
    final csvStr = const ListToCsvConverter(fieldDelimiter: ';')
        .convert(rows, eol: '\r\n');
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'visible_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvStr, encoding: utf8);
    return file;
  }

  Future<File> exportVisiblePdf({
    required List<TrainingResult> sessions,
    required List<TrainingResult> chartData,
    bool includeChart = true,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final table = pw.Table.fromTextArray(
            headers: const [
              'Date',
              'Accuracy',
              'Total',
              'Correct',
              'Tags',
              'Comment',
              'Notes'
            ],
            data: [
              for (final r in sessions)
                [
                  formatDateTime(r.date),
                  r.accuracy.toStringAsFixed(1),
                  r.total,
                  r.correct,
                  r.tags.join(';'),
                  r.comment ?? '',
                  r.notes ?? ''
                ]
            ],
          );

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (includeChart)
                pw.Container(
                  height: 200,
                  child: pw.Chart(
                    grid: pw.CartesianGrid(
                      xAxis: pw.FixedAxis.fromStrings(
                        [for (final r in chartData) formatDate(r.date)],
                        marginStart: 30,
                      ),
                      yAxis: pw.FixedAxis(
                        [0, 20, 40, 60, 80, 100],
                        divisions: true,
                        marginStart: 30,
                      ),
                    ),
                    datasets: [
                      pw.LineDataSet(
                        drawPoints: false,
                        isCurved: true,
                        data: [
                          for (var i = 0; i < chartData.length; i++)
                            pw.PointChartValue(
                              i.toDouble(),
                              chartData[i].accuracy,
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              if (includeChart) pw.SizedBox(height: 16),
              table,
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'visible_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<bool> deleteLatestExports(String? csvPath, String? pdfPath) async {
    bool deleted = false;
    if (csvPath != null) {
      final file = File(csvPath);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      }
    }
    if (pdfPath != null) {
      final file = File(pdfPath);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      }
    }
    return deleted;
  }
}

