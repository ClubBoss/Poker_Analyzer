import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:provider/provider.dart';
import '../services/tag_service.dart';
import 'package:flutter/services.dart';
import '../helpers/color_utils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../services/progress_export_service.dart';
import '../services/training_history_preferences.dart';
import '../services/training_history_prefs.dart';

import '../theme/app_colors.dart';
import '../widgets/history/accuracy_chart.dart';
import '../widgets/history/average_accuracy_chart.dart';
import '../widgets/history/accuracy_trend_chart.dart';
import '../widgets/common/history_list_item.dart';
import '../widgets/history/session_accuracy_bar_chart.dart';
import '../widgets/history/accuracy_distribution_chart.dart';
import 'training_history/training_history_controller.dart';
import 'training_detail_screen.dart';

import '../models/training_result.dart';
import '../models/training_session.dart';
import '../helpers/date_utils.dart';
import '../helpers/accuracy_utils.dart';
import '../tutorial/tutorial_flow.dart';
import '../widgets/sync_status_widget.dart';
import 'training_history/average_accuracy_summary.dart';
import 'training_history/filter_summary.dart';
import 'training_history/streak_summary.dart';

class TrainingHistoryScreen extends StatefulWidget {
  final TutorialFlow? tutorial;
  static final GlobalKey exportCsvKey = GlobalKey();

  const TrainingHistoryScreen({super.key, this.tutorial});

  @override
  State<TrainingHistoryScreen> createState() => _TrainingHistoryScreenState();
}

class _TrainingHistoryScreenState extends State<TrainingHistoryScreen> {

  final List<TrainingResult> _history = [];
  int _filterDays = 7;
  SortOption _sort = SortOption.newest;
  RatingFilter _ratingFilter = RatingFilter.all;
  AccuracyRange _accuracyRange = AccuracyRange.all;
  Set<String> _selectedTags = {};
  Set<String> _selectedTagColors = {};
  bool _showCharts = true;
  bool _showAvgChart = true;
  bool _showDistribution = true;
  bool _showTrendChart = true;
  bool _hideEmptyTags = false;
  bool _sortByTag = false;
  bool _includeChartInPdf = true;
  ChartMode _chartMode = ChartMode.daily;
  TagCountFilter _tagCountFilter = TagCountFilter.any;
  WeekdayFilter _weekdayFilter = WeekdayFilter.all;
  SessionLengthFilter _lengthFilter = SessionLengthFilter.any;
  bool _exportTags3Only = false;
  bool _exportNotesOnly = false;
  late TrainingHistoryPreferences _prefs;

  String? _lastCsvPath;
  String? _lastPdfPath;

  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.tutorial?.showCurrentStep(context);
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await TrainingHistoryPreferences.load();
    setState(() {
      _sort = _prefs.sort;
      _ratingFilter = _prefs.ratingFilter;
      _accuracyRange = _prefs.accuracyRange;
      _selectedTags = _prefs.selectedTags;
      _selectedTagColors = _prefs.selectedTagColors;
      _showCharts = _prefs.showCharts;
      _showAvgChart = _prefs.showAvgChart;
      _showDistribution = _prefs.showDistribution;
      _showTrendChart = _prefs.showTrendChart;
      _hideEmptyTags = _prefs.hideEmptyTags;
      _sortByTag = _prefs.sortByTag;
      _chartMode = _prefs.chartMode;
      _tagCountFilter = _prefs.tagCountFilter;
      _weekdayFilter = _prefs.weekdayFilter;
      _lengthFilter = _prefs.lengthFilter;
      _includeChartInPdf = _prefs.includeChartInPdf;
      _exportTags3Only = _prefs.exportTags3Only;
      _exportNotesOnly = _prefs.exportNotesOnly;
      _dateFrom = _prefs.dateFrom;
      _dateTo = _prefs.dateTo;
    });
    _loadHistory();
  }

  final TrainingHistoryController _controller =
      TrainingHistoryController.instance;

  Future<void> _loadHistory() async {
    final loaded = await _controller.loadHistory();
    setState(() {
      _history
        ..clear()
        ..addAll(loaded);
    });
  }

  Future<void> _clearHistory() async {
    await _controller.clearHistory();
    setState(() {
      _history.clear();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = [for (final r in _history) jsonEncode(r.toJson())];
    await prefs.setStringList('training_history', list);
  }

  Future<void> _exportHistory() async {
    if (_history.isEmpty) return;
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final r in _history) r.toJson()]);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_history_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.json');
  }

  Future<void> _exportCsv() async {
    final sessions = _getFilteredHistory()
        .where((r) => !_exportTags3Only || r.tags.length >= 3)
        .where((r) => !_exportNotesOnly || (r.notes?.trim().isNotEmpty ?? false))
        .toList();
    if (sessions.isEmpty) return;
    final rows = <List<dynamic>>[];
    final filters = _buildExportFilterLines();
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
  }

  Future<void> _exportMarkdown() async {
    final sessions = _getFilteredHistory()
        .where((r) => !_exportTags3Only || r.tags.length >= 3)
        .where((r) => !_exportNotesOnly || (r.notes?.trim().isNotEmpty ?? false))
        .toList();
    if (sessions.isEmpty) return;
    final buffer = StringBuffer();
    final filters = _buildExportFilterLines();
    if (filters.isNotEmpty) {
      buffer.writeln('## Filters');
      for (final line in filters) {
        buffer.writeln('- $line');
      }
      buffer.writeln();
    }
    for (final r in sessions) {
      final tags = r.tags.join(', ');
      final notes = r.notes ?? '';
      final comment = r.comment ?? '';
      buffer.writeln('### ${formatDateTime(r.date)}');
      buffer.writeln('- Accuracy: ${r.accuracy.toStringAsFixed(1)}%');
      if (tags.isNotEmpty) buffer.writeln('- Tags: $tags');
      if (comment.isNotEmpty) buffer.writeln('- Comment: $comment');
      if (notes.isNotEmpty) buffer.writeln('- Notes: $notes');
      buffer.writeln();
    }
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final name = 'training_history_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'md',
        mimeType: MimeType.other,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Экспортировано ${sessions.length} сессий в MD')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта MD')));
      }
    }
  }

  Future<void> _exportHtml() async {
    final sessions = _getFilteredHistory()
        .where((r) => !_exportTags3Only || r.tags.length >= 3)
        .where((r) => !_exportNotesOnly || (r.notes?.trim().isNotEmpty ?? false))
        .toList();
    if (sessions.isEmpty) return;
    const htmlEscape = HtmlEscape();
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln(
        '<html><head><meta charset="utf-8"><title>Training History</title></head><body>');
    final filters = _buildExportFilterLines();
    if (filters.isNotEmpty) {
      buffer.writeln('<h2>Filters</h2><ul>');
      for (final line in filters) {
        buffer.writeln('<li>${htmlEscape.convert(line)}</li>');
      }
      buffer.writeln('</ul>');
    }
    for (final r in sessions) {
      final tags = r.tags.join(', ');
      final notes = r.notes ?? '';
      final comment = r.comment ?? '';
      buffer.writeln('<h3>${formatDateTime(r.date)}</h3>');
      buffer.writeln('<ul>');
      buffer.writeln('<li>Accuracy: ${r.accuracy.toStringAsFixed(1)}%</li>');
      if (tags.isNotEmpty) {
        buffer.writeln('<li>Tags: ${htmlEscape.convert(tags)}</li>');
      }
      if (comment.isNotEmpty) {
        buffer.writeln('<li>Comment: ${htmlEscape.convert(comment)}</li>');
      }
      if (notes.isNotEmpty) {
        buffer.writeln('<li>Notes: ${htmlEscape.convert(notes)}</li>');
      }
      buffer.writeln('</ul>');
    }
    buffer.writeln('</body></html>');
    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    final name = 'training_history_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'html',
        mimeType: MimeType.other,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Экспортировано ${sessions.length} сессий в HTML')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта HTML')));
      }
    }
  }

  Future<void> _exportPdf() async {
    final sessions = _getFilteredHistory()
        .where((r) => !_exportTags3Only || r.tags.length >= 3)
        .where((r) => !_exportNotesOnly || (r.notes?.trim().isNotEmpty ?? false))
        .toList();
    if (sessions.isEmpty) return;

    final chartData = _groupSessionsForChart(sessions);

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
              if (_includeChartInPdf)
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
              if (_includeChartInPdf) pw.SizedBox(height: 16),
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

    _lastPdfPath = file.path;
    await Share.shareXFiles([XFile(file.path)], text: 'training_history.pdf');
  }

  Future<void> _exportJson() async {
    if (_history.isEmpty) return;
    final sessions = [
      for (final r in _history)
        TrainingSession(
          date: r.date,
          total: r.total,
          correct: r.correct,
          accuracy: r.accuracy,
          tags: r.tags,
          notes: r.notes,
          comment: r.comment,
        )
    ];
    const encoder = JsonEncoder.withIndent('  ');
    final bytes = Uint8List.fromList(
      utf8.encode(encoder.convert([for (final s in sessions) s.toJson()])),
    );
    final name = 'training_history_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'json',
        mimeType: MimeType.other,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Экспортировано ${sessions.length} сессий в JSON')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
                const SnackBar(content: Text('Ошибка экспорта JSON')));
      }
    }
  }

  Future<void> _exportChartCsv() async {
    final filtered = _getFilteredHistory();
    final grouped = _groupSessionsForChart(filtered);
    if (grouped.isEmpty) return;

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

    String mode;
    switch (_chartMode) {
      case ChartMode.daily:
        mode = 'daily';
        break;
      case ChartMode.weekly:
        mode = 'weekly';
        break;
      case ChartMode.monthly:
        mode = 'monthly';
        break;
    }

    final fileName = 'chart_${mode}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvStr, encoding: utf8);

    _lastCsvPath = file.path;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $fileName')),
      );
    }
  }

  Future<void> _copyVisibleResults() async {
    final sessions = _getFilteredHistory();
    if (sessions.isEmpty) return;
    final lines = <String>[];
    for (final r in sessions) {
      final tags = r.tags.join(', ');
      final notes = r.notes ?? '';
      final comment = r.comment ?? '';
      lines.add(
          '${formatDateTime(r.date)} - ${r.accuracy.toStringAsFixed(1)}% - '
          '${r.correct}/${r.total}'
          '${tags.isNotEmpty ? ' - Tags: $tags' : ''}'
          '${comment.isNotEmpty ? ' - Comment: $comment' : ''}'
          '${notes.isNotEmpty ? ' - Notes: $notes' : ''}');
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\\n')));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Скопировано ${sessions.length} сессий')),
      );
    }
  }

  Future<void> _exportVisibleCsv() async {
    final sessions = _getFilteredHistory()
        .where((r) => !_exportTags3Only || r.tags.length >= 3)
        .where((r) => !_exportNotesOnly || (r.notes?.trim().isNotEmpty ?? false))
        .toList();
    if (sessions.isEmpty) return;
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
    final fileName =
        'visible_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvStr, encoding: utf8);

    _lastCsvPath = file.path;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $fileName')),
      );
    }
  }

  Future<void> _exportVisiblePdf() async {
    final sessions = _getFilteredHistory()
        .where((r) => !_exportTags3Only || r.tags.length >= 3)
        .where((r) => !_exportNotesOnly || (r.notes?.trim().isNotEmpty ?? false))
        .toList();
    if (sessions.isEmpty) return;

    final chartData = _groupSessionsForChart(sessions);

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
              if (_includeChartInPdf)
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
              if (_includeChartInPdf) pw.SizedBox(height: 16),
              table,
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'visible_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    _lastPdfPath = file.path;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: $fileName')),
      );
    }
  }

  Future<void> _exportProgressCsv({bool weekly = false}) async {
    final service = ProgressExportService(
        stats: context.read<TrainingStatsService>());
    final file = await service.exportCsv(weekly: weekly);
    _lastCsvPath = file.path;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path.split('/').last}')),
      );
    }
  }

  Future<void> _exportProgressPdf({bool weekly = false}) async {
    final service = ProgressExportService(
        stats: context.read<TrainingStatsService>());
    final file = await service.exportPdf(weekly: weekly);
    _lastPdfPath = file.path;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл сохранён: ${file.path.split('/').last}')),
      );
    }
  }

  Future<void> _shareLatestExport() async {
    if (_lastCsvPath == null && _lastPdfPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет экспортированных файлов')),
        );
      }
      return;
    }

    String? selectedPath;
    if (_lastCsvPath != null && _lastPdfPath != null) {
      selectedPath = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Последний CSV'),
                onTap: () => Navigator.pop(context, _lastCsvPath),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Последний PDF'),
                onTap: () => Navigator.pop(context, _lastPdfPath),
              ),
            ],
          ),
        ),
      );
    } else {
      selectedPath = _lastCsvPath ?? _lastPdfPath;
    }

    if (selectedPath == null) return;
    final file = File(selectedPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не найден')),
        );
      }
      return;
    }

    await Share.shareXFiles([XFile(file.path)]);
  }

  Future<void> _openLatestExport() async {
    if (_lastCsvPath == null && _lastPdfPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет экспортированных файлов')),
        );
      }
      return;
    }

    String? selectedPath;
    if (_lastCsvPath != null && _lastPdfPath != null) {
      selectedPath = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Последний CSV'),
                onTap: () => Navigator.pop(context, _lastCsvPath),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Последний PDF'),
                onTap: () => Navigator.pop(context, _lastPdfPath),
              ),
            ],
          ),
        ),
      );
    } else {
      selectedPath = _lastCsvPath ?? _lastPdfPath;
    }

    if (selectedPath == null) return;
    final file = File(selectedPath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл не найден')),
        );
      }
      return;
    }

    await OpenFilex.open(file.path);
  }

  Future<void> _deleteLatestExports() async {
    if (_lastCsvPath == null && _lastPdfPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет экспортированных файлов')),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить файлы?'),
          content:
              const Text('Удалить последние экспортированные файлы?'),
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
        );
      },
    );

    if (confirm != true) return;

    bool deleted = false;

    if (_lastCsvPath != null) {
      final file = File(_lastCsvPath!);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      }
    }

    if (_lastPdfPath != null) {
      final file = File(_lastPdfPath!);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      }
    }

    setState(() {
      _lastCsvPath = null;
      _lastPdfPath = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deleted
              ? 'Файлы удалены'
              : 'Файлы не найдены'),
        ),
      );
    }
  }

  Future<void> _importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! List) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file format')),
        );
        return;
      }
      final List<TrainingSession> sessions = [];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            sessions.add(
                TrainingSession.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
      if (sessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid file format')),
        );
        return;
      }
      setState(() {
        _history.addAll([for (final s in sessions) s.toTrainingResult()]);
      });
      await _saveHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported ${sessions.length} sessions')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid file format')),
      );
    }
  }


  Future<void> _resetFilters() async {
    await _prefs.resetFilters();
    setState(() {
      _sort = SortOption.newest;
      _ratingFilter = RatingFilter.all;
      _accuracyRange = AccuracyRange.all;
      _tagCountFilter = TagCountFilter.any;
      _weekdayFilter = WeekdayFilter.all;
      _lengthFilter = SessionLengthFilter.any;
      _selectedTags.clear();
      _selectedTagColors.clear();
      _sortByTag = false;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Future<void> _clearTagFilters() async {
    await _prefs.clearTagFilters();
    setState(() => _selectedTags.clear());
  }

  Future<void> _clearColorFilters() async {
    await _prefs.clearColorFilters();
    setState(() => _selectedTagColors.clear());
  }

  Future<void> _clearLengthFilter() async {
    await _prefs.clearLengthFilter();
    setState(() => _lengthFilter = SessionLengthFilter.any);
  }

  Future<void> _clearAccuracyFilter() async {
    await _prefs.clearAccuracyFilter();
    setState(() => _accuracyRange = AccuracyRange.all);
  }

  Future<void> _clearDateFilter() async {
    await _prefs.clearDateFilter();
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
  }

  List<TrainingResult> _getFilteredHistory({Set<String>? tags, Set<String>? colors}) {
    final cutoff = DateTime.now().subtract(Duration(days: _filterDays));
    final selected = tags ?? _selectedTags;
    final selectedColors = colors ?? _selectedTagColors;
    final tagService = context.read<TagService>();

    bool matchesTag(TrainingResult r) {
      final tagMatch = selected.isNotEmpty && r.tags.any(selected.contains);
      final colorMatch = selectedColors.isNotEmpty &&
          r.tags.any((t) => selectedColors.contains(tagService.colorOf(t)));
      return tagMatch || colorMatch;
    }

    final list = _history
        .where((r) => r.date.isAfter(cutoff))
        .where((r) => _dateFrom == null || !r.date.isBefore(_dateFrom!))
        .where((r) => _dateTo == null || !r.date.isAfter(_dateTo!))
        .where((r) {
          final min = switch (_ratingFilter) {
            RatingFilter.all => 0,
            RatingFilter.pct40 => 40,
            RatingFilter.pct60 => 60,
            RatingFilter.pct80 => 80,
          };
          return r.accuracy >= min;
        })
        .where((r) {
          switch (_accuracyRange) {
            case AccuracyRange.all:
              return true;
            case AccuracyRange.lt50:
              return r.accuracy < 50;
            case AccuracyRange.pct50to75:
              return r.accuracy >= 50 && r.accuracy < 75;
            case AccuracyRange.pct75plus:
              return r.accuracy >= 75;
          }
        })
        .where((r) {
          switch (_tagCountFilter) {
            case TagCountFilter.any:
              return true;
            case TagCountFilter.one:
              return r.tags.length == 1;
            case TagCountFilter.twoPlus:
              return r.tags.length >= 2;
            case TagCountFilter.threePlus:
              return r.tags.length >= 3;
          }
        })
        .where((r) {
          switch (_weekdayFilter) {
            case WeekdayFilter.all:
              return true;
            case WeekdayFilter.mon:
              return r.date.weekday == DateTime.monday;
            case WeekdayFilter.tue:
              return r.date.weekday == DateTime.tuesday;
            case WeekdayFilter.wed:
              return r.date.weekday == DateTime.wednesday;
            case WeekdayFilter.thu:
              return r.date.weekday == DateTime.thursday;
            case WeekdayFilter.fri:
              return r.date.weekday == DateTime.friday;
            case WeekdayFilter.sat:
              return r.date.weekday == DateTime.saturday;
            case WeekdayFilter.sun:
              return r.date.weekday == DateTime.sunday;
          }
        })
        .where((r) {
          switch (_lengthFilter) {
            case SessionLengthFilter.any:
              return true;
            case SessionLengthFilter.oneToFive:
              return r.total >= 1 && r.total <= 5;
            case SessionLengthFilter.sixToTen:
              return r.total >= 6 && r.total <= 10;
            case SessionLengthFilter.elevenPlus:
              return r.total >= 11;
          }
        })
        .where((r) {
          if (_sortByTag) return true;
          if (selected.isEmpty) return true;
          return r.tags.any(selected.contains);
        })
        .where((r) {
          if (_sortByTag) return true;
          if (selectedColors.isEmpty) return true;
          return r.tags.any((t) => selectedColors.contains(tagService.colorOf(t)));
        })
        .toList();

    int compareBase(TrainingResult a, TrainingResult b) {
      switch (_sort) {
        case SortOption.newest:
          return b.date.compareTo(a.date);
        case SortOption.oldest:
          return a.date.compareTo(b.date);
        case SortOption.position:
          int idx(String? p) {
            const order = ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'];
            return order.indexOf(p ?? '');
          }
          final ap = a.tags.firstWhere(
              (t) => ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'].contains(t),
              orElse: () => '');
          final bp = b.tags.firstWhere(
              (t) => ['UTG', 'MP', 'CO', 'BTN', 'SB', 'BB'].contains(t),
              orElse: () => '');
          final ai = idx(ap);
          final bi = idx(bp);
          if (ai != bi) return ai.compareTo(bi);
          return b.date.compareTo(a.date);
        case SortOption.mistakes:
          final am = a.total - a.correct;
          final bm = b.total - b.correct;
          if (am != bm) return bm.compareTo(am);
          return b.date.compareTo(a.date);
        case SortOption.evDiff:
          final ae = a.evDiff ?? 0;
          final be = b.evDiff ?? 0;
          if (ae != be) return be.compareTo(ae);
          return b.date.compareTo(a.date);
        case SortOption.icmDiff:
          final ai = a.icmDiff ?? 0;
          final bi = b.icmDiff ?? 0;
          if (ai != bi) return bi.compareTo(ai);
          return b.date.compareTo(a.date);
      }
    }

    list.sort((a, b) {
      if (_sortByTag && (selected.isNotEmpty || selectedColors.isNotEmpty)) {
        final aMatch = matchesTag(a);
        final bMatch = matchesTag(b);
        if (aMatch && !bMatch) return -1;
        if (!aMatch && bMatch) return 1;
      }
      return compareBase(a, b);
    });
    return list;
  }

  double _calculateAverageAccuracy(List<TrainingResult> list) {
    if (list.isEmpty) return 0.0;
    final sum = list.map((e) => e.accuracy).reduce((a, b) => a + b);
    return sum / list.length;
  }

  int _calculateCurrentStreak() {
    if (_history.isEmpty) return 0;
    final days = _history
        .map((r) {
          final d = r.date.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort();
    var streak = 1;
    var prev = days.last;
    for (var i = days.length - 2; i >= 0; i--) {
      final current = days[i];
      if (prev.difference(current).inDays == 1) {
        streak++;
        prev = current;
      } else {
        break;
      }
    }
    return streak;
  }

  int _calculateBestStreak() {
    if (_history.isEmpty) return 0;
    final days = _history
        .map((r) {
          final d = r.date.toLocal();
          return DateTime(d.year, d.month, d.day);
        })
        .toSet()
        .toList()
      ..sort();

    var best = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current++;
      } else if (diff > 1) {
        if (current > best) best = current;
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }

  List<TrainingResult> _groupSessionsForChart(List<TrainingResult> list) {
    if (_chartMode == ChartMode.daily) {
      final sorted = [...list]..sort((a, b) => a.date.compareTo(b.date));
      return sorted;
    }

    final Map<DateTime, List<TrainingResult>> groups = {};
    for (final r in list) {
      DateTime key;
      switch (_chartMode) {
        case ChartMode.weekly:
          final d = DateTime(r.date.year, r.date.month, r.date.day);
          key = d.subtract(Duration(days: d.weekday - 1));
          break;
        case ChartMode.monthly:
          key = DateTime(r.date.year, r.date.month);
          break;
        case ChartMode.daily:
          key = DateTime(r.date.year, r.date.month, r.date.day);
          break;
      }
      groups.putIfAbsent(key, () => []).add(r);
    }
    final result = <TrainingResult>[];
    final keys = groups.keys.toList()..sort();
    for (final k in keys) {
      final sessions = groups[k]!;
      final total = sessions.fold<int>(0, (p, e) => p + e.total);
      final correct = sessions.fold<int>(0, (p, e) => p + e.correct);
      final accuracy = total == 0 ? 0.0 : correct * 100 / total;
      result.add(TrainingResult(
        date: k,
        total: total,
        correct: correct,
        accuracy: accuracy,
        tags: const [],
      ));
    }
    return result;
  }

  String _getActiveFilterSummary() {
    final parts = <String>[];
    if (_tagCountFilter != TagCountFilter.any) {
      final label = switch (_tagCountFilter) {
        TagCountFilter.one => '1 тег',
        TagCountFilter.twoPlus => '2+',
        TagCountFilter.threePlus => '3+',
        _ => '',
      };
      if (label.isNotEmpty) parts.add('теги: $label');
    }
    if (_ratingFilter != RatingFilter.all) {
      final label = switch (_ratingFilter) {
        RatingFilter.pct40 => '40%+',
        RatingFilter.pct60 => '60%+',
        RatingFilter.pct80 => '80%+',
        _ => '',
      };
      if (label.isNotEmpty) parts.add('рейтинг: $label');
    }
    if (_accuracyRange != AccuracyRange.all) {
      final label = switch (_accuracyRange) {
        AccuracyRange.lt50 => '<50%',
        AccuracyRange.pct50to75 => '50–75%',
        AccuracyRange.pct75plus => '>75%',
        _ => '',
      };
      if (label.isNotEmpty) parts.add('точность: $label');
    }
    if (_lengthFilter != SessionLengthFilter.any) {
      final label = switch (_lengthFilter) {
        SessionLengthFilter.oneToFive => '1–5',
        SessionLengthFilter.sixToTen => '6–10',
        SessionLengthFilter.elevenPlus => '11+',
        _ => '',
      };
      if (label.isNotEmpty) parts.add('длина: $label');
    }
    return parts.join(' + ');
  }


  Widget _buildQuickTagRow() {
    final tags = <String>{};
    for (final r in _history) {
      tags.addAll(r.tags);
    }
    if (tags.isEmpty) return const SizedBox.shrink();
    final tagService = context.read<TagService>();
    final tagsList = tags.toList();
    final showClear = _selectedTags.isNotEmpty;
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tagsList.length + (showClear ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < tagsList.length) {
            final tag = tagsList[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                selectedColor: colorFromHex(tagService.colorOf(tag)),
                onSelected: (selected) async {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                  await _prefs.setSelectedTags(_selectedTags);
                },
              ),
            );
          }
          return IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white70,
            tooltip: 'Очистить',
            onPressed: _clearTagFilters,
          );
        },
      ),
    );
  }

  Widget _buildQuickLengthRow() {
    const items = {
      SessionLengthFilter.any: 'Все',
      SessionLengthFilter.oneToFive: '1–5',
      SessionLengthFilter.sixToTen: '6–10',
      SessionLengthFilter.elevenPlus: '11+',
    };
    final entries = items.entries.toList();
    final showClear = _lengthFilter != SessionLengthFilter.any;
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length + (showClear ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < entries.length) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _lengthFilter == entry.key,
                onSelected: (selected) async {
                  if (!selected) return;
                  await _prefs.setLengthFilter(entry.key);
                  setState(() => _lengthFilter = entry.key);
                },
              ),
            );
          }
          return IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white70,
            tooltip: 'Очистить',
            onPressed: _clearLengthFilter,
          );
        },
      ),
    );
  }

  Widget _buildQuickAccuracyRow() {
    const items = {
      AccuracyRange.lt50: '<50%',
      AccuracyRange.pct50to75: '50–75%',
      AccuracyRange.pct75plus: '>75%',
      AccuracyRange.all: 'Все',
    };
    final entries = items.entries.toList();
    final showClear = _accuracyRange != AccuracyRange.all;
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length + (showClear ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < entries.length) {
            final entry = entries[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: _accuracyRange == entry.key,
                onSelected: (selected) async {
                  if (!selected) return;
                  await _prefs.setAccuracyRange(entry.key);
                  setState(() => _accuracyRange = entry.key);
                },
              ),
            );
          }
          return IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white70,
            tooltip: 'Очистить',
            onPressed: _clearAccuracyFilter,
          );
        },
      ),
    );
  }

  Widget _buildQuickColorRow() {
    final tagService = context.read<TagService>();
    final colors = <String>{};
    for (final r in _history) {
      for (final tag in r.tags) {
        colors.add(tagService.colorOf(tag));
      }
    }
    if (colors.isEmpty) return const SizedBox.shrink();
    final Map<String, List<String>> colorMap = {};
    for (final tag in tagService.tags) {
      colorMap.putIfAbsent(tagService.colorOf(tag), () => []).add(tag);
    }
    final colorList = colors.toList();
    final showClear = _selectedTagColors.isNotEmpty;
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: colorList.length + (showClear ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < colorList.length) {
            final color = colorList[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(colorMap[color]?.join(', ') ?? color),
                selected: _selectedTagColors.contains(color),
                selectedColor: colorFromHex(color),
                onSelected: (selected) async {
                  setState(() {
                    if (selected) {
                      _selectedTagColors.add(color);
                    } else {
                      _selectedTagColors.remove(color);
                    }
                  });
                  await _prefs.setSelectedTagColors(_selectedTagColors);
                },
              ),
            );
          }
          return IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: Colors.white70,
            tooltip: 'Очистить',
            onPressed: _clearColorFilters,
          );
        },
      ),
    );
  }

  bool _hasResultsForTag(String tag) {
    return _getFilteredHistory(tags: {tag}).isNotEmpty;
  }

  bool _hasResultsForColor(String color) {
    return _getFilteredHistory(colors: {color}).isNotEmpty;
  }

  List<String> _buildExportFilterLines() {
    final lines = <String>[];
    if (_selectedTags.isNotEmpty) {
      lines.add('Tags: ${_selectedTags.join(', ')}');
    }
    if (_ratingFilter != RatingFilter.all) {
      final label = switch (_ratingFilter) {
        RatingFilter.pct40 => '40%+',
        RatingFilter.pct60 => '60%+',
        RatingFilter.pct80 => '80%+',
        _ => '',
      };
      if (label.isNotEmpty) lines.add('Rating: $label');
    }
    if (_accuracyRange != AccuracyRange.all) {
      final label = switch (_accuracyRange) {
        AccuracyRange.lt50 => '<50%',
        AccuracyRange.pct50to75 => '50-75%',
        AccuracyRange.pct75plus => '>75%',
        _ => '',
      };
      if (label.isNotEmpty) lines.add('Accuracy: $label');
    }
    if (_lengthFilter != SessionLengthFilter.any) {
      final label = switch (_lengthFilter) {
        SessionLengthFilter.oneToFive => '1-5',
        SessionLengthFilter.sixToTen => '6-10',
        SessionLengthFilter.elevenPlus => '11+',
        _ => '',
      };
      if (label.isNotEmpty) lines.add('Session length: $label');
    }
    if (_dateFrom != null || _dateTo != null) {
      final fromStr = _dateFrom != null ? formatDate(_dateFrom!) : '';
      final toStr = _dateTo != null ? formatDate(_dateTo!) : '';
      lines.add('Date range: ${fromStr.isEmpty ? '...' : fromStr} - '
          '${toStr.isEmpty ? '...' : toStr}');
    }
    return lines;
  }

  Future<void> _showTagSelector() async {
    final tags = context.read<TagService>().tags.toSet();
    final local = Set<String>.from(_selectedTags);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Фильтр по тегам',
              style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags.elementAt(index);
                    return CheckboxListTile(
                      value: local.contains(tag),
                      title: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                                color: colorFromHex(
                                    context.read<TagService>().colorOf(tag)),
                                shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(tag,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                      onChanged: (checked) {
                        setStateDialog(() {
                          if (checked ?? false) {
                            local.add(tag);
                          } else {
                            local.remove(tag);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _prefs.setSelectedTags(result);
      setState(() => _selectedTags = result);
    }
  }

  Future<void> _showColorSelector() async {
    final service = context.read<TagService>();
    final Map<String, List<String>> colorMap = {};
    for (final tag in service.tags) {
      colorMap.putIfAbsent(service.colorOf(tag), () => []).add(tag);
    }
    final colors = colorMap.keys.toList();
    final local = Set<String>.from(_selectedTagColors);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Фильтр по цветам',
              style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    final color = colors[index];
                    return CheckboxListTile(
                      activeColor: colorFromHex(color),
                      value: local.contains(color),
                      title: Text(
                        colorMap[color]!.join(', '),
                        style: const TextStyle(color: Colors.white),
                      ),
                      secondary: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorFromHex(color),
                          shape: BoxShape.circle,
                        ),
                      ),
                      onChanged: (checked) {
                        setStateDialog(() {
                          if (checked ?? false) {
                            local.add(color);
                          } else {
                            local.remove(color);
                          }
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      await _prefs.setSelectedTagColors(result);
      setState(() => _selectedTagColors = result);
    }
  }

  Future<void> _editSessionTags(BuildContext ctx, TrainingResult session) async {
    final tags = context.read<TagService>().tags;
    final local = List<String>.from(session.tags);
    final updated = await showDialog<List<String>>(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Теги сессии',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (local.isNotEmpty)
                      SizedBox(
                        height: 150,
                        child: ReorderableListView(
                          shrinkWrap: true,
                          onReorder: (oldIndex, newIndex) {
                            setStateDialog(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = local.removeAt(oldIndex);
                              local.insert(newIndex, item);
                            });
                          },
                          children: [
                            for (final tag in local)
                              ListTile(
                                key: ValueKey(tag),
                                title: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: colorFromHex(context
                                            .read<TagService>()
                                            .colorOf(tag)),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(tag,
                                        style: const TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tags.length,
                        itemBuilder: (context, index) {
                          final tag = tags[index];
                          return CheckboxListTile(
                            value: local.contains(tag),
                            title: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: colorFromHex(context
                                        .read<TagService>()
                                        .colorOf(tag)),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(tag,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ],
                            ),
                            onChanged: (checked) {
                              setStateDialog(() {
                                if (checked ?? false) {
                                  if (!local.contains(tag)) local.add(tag);
                                } else {
                                  local.remove(tag);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (updated != null) {
      final index = _history.indexOf(session);
      if (index != -1) {
        setState(() {
          _history[index] = TrainingResult(
            date: session.date,
            total: session.total,
            correct: session.correct,
            accuracy: session.accuracy,
            tags: updated,
            notes: session.notes,
            evDiff: session.evDiff,
            icmDiff: session.icmDiff,
          );
        });
        await _saveHistory();
      }
    }
  }

  Future<void> _editSessionNotes(BuildContext ctx, TrainingResult session) async {
    final controller = TextEditingController(text: session.notes ?? '');
    final updated = await showDialog<String>(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Заметки',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Введите заметки',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (updated != null) {
      final index = _history.indexOf(session);
      if (index != -1) {
        final text = updated.trim();
        setState(() {
          _history[index] = TrainingResult(
            date: session.date,
            total: session.total,
            correct: session.correct,
            accuracy: session.accuracy,
            tags: session.tags,
            notes: text.isEmpty ? null : text,
            evDiff: session.evDiff,
            icmDiff: session.icmDiff,
          );
        });
        await _saveHistory();
      }
    }
  }

  Future<void> _editSessionComment(
      BuildContext ctx, TrainingResult session) async {
    final controller = TextEditingController(text: session.comment ?? '');
    final updated = await showDialog<String>(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Комментарий',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 1,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Введите комментарий',
              hintStyle: TextStyle(color: Colors.white54),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (updated != null) {
      final index = _history.indexOf(session);
      if (index != -1) {
        final text = updated.trim();
        setState(() {
          _history[index] = TrainingResult(
            date: session.date,
            total: session.total,
            correct: session.correct,
            accuracy: session.accuracy,
            tags: session.tags,
            notes: session.notes,
            comment: text.isEmpty ? null : text,
            evDiff: session.evDiff,
            icmDiff: session.icmDiff,
          );
        });
        await _saveHistory();
      }
    }
  }

  Future<void> _editSessionAccuracy(
      BuildContext ctx, TrainingResult session) async {
    final correctController =
        TextEditingController(text: session.correct.toString());
    final totalController =
        TextEditingController(text: session.total.toString());
    final List<int>? updated = await showDialog<List<int>>(
      context: ctx,
      builder: (context) {
        int? correct = session.correct;
        int? total = session.total;
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Edit Accuracy',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: correctController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Correct'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) {
                      setStateDialog(() => correct = int.tryParse(v));
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total'),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) {
                      setStateDialog(() => total = int.tryParse(v));
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: correct != null && total != null && total! > 0
                  ? () => Navigator.pop(context, [correct!, total!])
                  : null,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    final index = _history.indexOf(session);
    if (index != -1) {
      final correct = updated[0];
      final total = updated[1];
      final newAccuracy = calculateAccuracy(correct, total);
      setState(() {
        _history[index] = TrainingResult(
          date: session.date,
          total: total,
          correct: correct,
          accuracy: newAccuracy,
          tags: session.tags,
          notes: session.notes,
          evDiff: session.evDiff,
          icmDiff: session.icmDiff,
        );
      });
      await _saveHistory();
    }
    }

  Future<void> _editSessionDate(TrainingResult session) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: session.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final index = _history.indexOf(session);
      if (index != -1) {
        final newDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          session.date.hour,
          session.date.minute,
          session.date.second,
          session.date.millisecond,
          session.date.microsecond,
        );
        setState(() {
          _history[index] = TrainingResult(
            date: newDate,
            total: session.total,
            correct: session.correct,
            accuracy: session.accuracy,
            tags: session.tags,
            notes: session.notes,
            evDiff: session.evDiff,
            icmDiff: session.icmDiff,
          );
        });
        await _saveHistory();
      }
    }
  }

  Future<void> _deleteSession(TrainingResult session) async {
    setState(() {
      _history.remove(session);
    });
    await _saveHistory();
  }

  Future<void> _confirmDelete(TrainingResult session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Session?'),
          content: const Text('Are you sure you want to delete this session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm ?? false) {
      await _deleteSession(session);
    }
  }

  Future<void> _setChartsVisible(bool value) async {
    setState(() => _showCharts = value);
    await _prefs.setShowCharts(_showCharts);
  }

  Future<void> _setAvgChartVisible(bool value) async {
    setState(() => _showAvgChart = value);
    await _prefs.setShowAvgChart(_showAvgChart);
  }

  Future<void> _setDistributionVisible(bool value) async {
    setState(() => _showDistribution = value);
    await _prefs.setShowDistribution(_showDistribution);
  }

  Future<void> _setTrendChartVisible(bool value) async {
    setState(() => _showTrendChart = value);
    await _prefs.setShowTrendChart(_showTrendChart);
  }

  Future<void> _setIncludeChartInPdf(bool value) async {
    setState(() => _includeChartInPdf = value);
    await _prefs.setIncludeChartInPdf(_includeChartInPdf);
  }

  Future<void> _setExportTags3Only(bool value) async {
    setState(() => _exportTags3Only = value);
    await _prefs.setExportTags3Only(_exportTags3Only);
  }

  Future<void> _setExportNotesOnly(bool value) async {
    setState(() => _exportNotesOnly = value);
    await _prefs.setExportNotesOnly(_exportNotesOnly);
  }

  Future<void> _setHideEmptyTags(bool value) async {
    setState(() => _hideEmptyTags = value);
    await _prefs.setHideEmptyTags(_hideEmptyTags);
  }

  Future<void> _setSortByTag(bool value) async {
    setState(() => _sortByTag = value);
    await _prefs.setSortByTag(_sortByTag);
  }

  Future<void> _setChartMode(ChartMode mode) async {
    setState(() => _chartMode = mode);
    await _prefs.setChartMode(mode);
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateFrom != null && _dateTo != null
          ? DateTimeRange(start: _dateFrom!, end: _dateTo!)
          : null,
    );
    if (range != null) {
      await _prefs.setDateRange(range.start, range.end);
      setState(() {
        _dateFrom = DateUtils.dateOnly(range.start);
        _dateTo = DateUtils.dateOnly(range.end);
      });
    }
  }

  String _dateRangeLabel() {
    if (_dateFrom == null && _dateTo == null) return '';
    final fromStr = _dateFrom != null ? formatDate(_dateFrom!) : '...';
    final toStr = _dateTo != null ? formatDate(_dateTo!) : '...';
    return '$fromStr - $toStr';
  }

  Future<void> _applyQuickDateFilter(int days) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final from = DateUtils.dateOnly(now.subtract(Duration(days: days - 1)));
    await _prefs.setDateRange(from, now);
    setState(() {
      _dateFrom = from;
      _dateTo = now;
    });
    _loadHistory();
  }

  void _openSessionDetail(TrainingResult session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingDetailScreen(
          result: session,
          onDelete: () async {
            await _deleteSession(session);
          },
          onEditTags: (ctx) async {
            await _editSessionTags(ctx, session);
          },
          onEditAccuracy: (ctx) async {
            await _editSessionAccuracy(ctx, session);
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training History'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context), 
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import',
            onPressed: _importJson,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _history.isEmpty ? null : _exportHistory,
          ),
          TextButton(
            onPressed: _clearHistory,
            child: const Text('Clear History'),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _history.isEmpty
          ? const Center(
              child: Text(
                'No history available.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Show:', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _filterDays,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                          DropdownMenuItem(value: 30, child: Text('30 days')),
                          DropdownMenuItem(value: 90, child: Text('90 days')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _filterDays = value;
                            });
                          }
                        },
                      ),
                      const Spacer(),
                  Builder(builder: (context) {
                    final filtered = _getFilteredHistory();
                    final avg = _calculateAverageAccuracy(filtered);
                    return Text(
                      'Average Accuracy: ${avg.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white),
                    );
                  })
                ],
              ),
            ),
            if (_showCharts)
              Builder(builder: (context) {
                final filtered = _getFilteredHistory();
                final last7days = _history
                    .where((r) =>
                        r.date.isAfter(DateTime.now().subtract(const Duration(days: 7))))
                    .toList();
                return Column(
                  children: [
                    AccuracyChart(sessions: filtered),
                    SessionAccuracyBarChart(sessions: last7days),
                  ],
                );
              }),
            _buildQuickTagRow(),
            _buildQuickColorRow(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Скрыть пустые теги',
                      style: TextStyle(color: Colors.white)),
                  const Spacer(),
                  Switch(
                    value: _hideEmptyTags,
                    onChanged: _setHideEmptyTags,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Фильтр по тегам',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _showTagSelector,
                        child: Text(
                            _selectedTags.isEmpty ? 'Выбрать теги' : 'Изменить'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            _selectedTags.isEmpty ? null : _clearTagFilters,
                        child: const Text('Сбросить теги'),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (context) {
                  final visibleTags = _hideEmptyTags
                      ? [
                          for (final t in _selectedTags)
                            if (_hasResultsForTag(t)) t
                        ]
                      : _selectedTags.toList();
                  return visibleTags.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 40,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: visibleTags.length,
                            itemBuilder: (context, index) {
                              final tag = visibleTags[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FilterChip(
                                  label: Text(tag),
                                  selected: true,
                                  backgroundColor: colorFromHex(
                                      context.read<TagService>().colorOf(tag)),
                                  onSelected: (selected) async {
                                    setState(() {
                                      _selectedTags.remove(tag);
                                    });
                                    await _prefs.setSelectedTags(
                                        _selectedTags);
                                  },
                                ),
                              );
                            },
                          ),
                        );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Игнорировать сессии без заметок',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Checkbox(
                        value: _exportNotesOnly,
                        onChanged: (v) => _setExportNotesOnly(v ?? false),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Фильтр по цвету',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _showColorSelector,
                        child: Text(
                            _selectedTagColors.isEmpty ? 'Выбрать цвета' : 'Изменить'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            _selectedTagColors.isEmpty ? null : _clearColorFilters,
                        child: const Text('Сбросить цвета'),
                      ),
                    ],
                  ),
                ),
                Builder(builder: (context) {
                  final visibleColors = _hideEmptyTags
                      ? [
                          for (final c in _selectedTagColors)
                            if (_hasResultsForColor(c)) c
                        ]
                      : _selectedTagColors.toList();
                  final service = context.read<TagService>();
                  final Map<String, List<String>> map = {};
                  for (final tag in service.tags) {
                    map.putIfAbsent(service.colorOf(tag), () => []).add(tag);
                  }
                  return visibleColors.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 40,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: visibleColors.length,
                            itemBuilder: (context, index) {
                              final color = visibleColors[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: FilterChip(
                                  label: Text(map[color]!.join(', ')),
                                  selected: true,
                                  backgroundColor: colorFromHex(color),
                                  onSelected: (selected) async {
                                    setState(() {
                                      _selectedTagColors.remove(color);
                                    });
                                    await _prefs.setSelectedTagColors(
                                        _selectedTagColors);
                                  },
                                ),
                              );
                            },
                          ),
                        );
                }),
                _buildQuickLengthRow(),
                _buildQuickAccuracyRow(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Сортировать по тегам',
                          style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      Switch(
                        value: _sortByTag,
                        onChanged: _setSortByTag,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Фильтр по рейтингу',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<RatingFilter>(
                        value: _ratingFilter,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: RatingFilter.all, child: Text('Все')),
                          DropdownMenuItem(
                              value: RatingFilter.pct40, child: Text('40%+')),
                          DropdownMenuItem(
                              value: RatingFilter.pct60, child: Text('60%+')),
                          DropdownMenuItem(
                              value: RatingFilter.pct80, child: Text('80%+')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await _prefs.setRatingFilter(value);
                          setState(() => _ratingFilter = value);
                        },
                      ),
                      const SizedBox(width: 16),
                      const Text('Sort By',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<SortOption>(
                        value: _sort,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: SortOption.newest,
                              child: Text('Newest First')),
                          DropdownMenuItem(
                              value: SortOption.oldest,
                              child: Text('Oldest First')),
                          DropdownMenuItem(
                              value: SortOption.position,
                              child: Text('Hero Position')),
                          DropdownMenuItem(
                              value: SortOption.mistakes,
                              child: Text('Mistakes First')),
                          DropdownMenuItem(
                              value: SortOption.evDiff,
                              child: Text('EV Change')),
                          DropdownMenuItem(
                              value: SortOption.icmDiff,
                              child: Text('ICM Change')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await _prefs.setSort(value);
                          setState(() => _sort = value);
                        },
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Сбросить фильтры'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Кол-во тегов',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<TagCountFilter>(
                        value: _tagCountFilter,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: TagCountFilter.any, child: Text('Любое')),
                          DropdownMenuItem(
                              value: TagCountFilter.one, child: Text('1 тег')),
                          DropdownMenuItem(
                              value: TagCountFilter.twoPlus, child: Text('2+')),
                          DropdownMenuItem(
                              value: TagCountFilter.threePlus, child: Text('3+')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await _prefs.setTagCountFilter(value);
                          setState(() => _tagCountFilter = value);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('День недели',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<WeekdayFilter>(
                        value: _weekdayFilter,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: WeekdayFilter.all, child: Text('Все')),
                          DropdownMenuItem(
                              value: WeekdayFilter.mon, child: Text('Пн')),
                          DropdownMenuItem(
                              value: WeekdayFilter.tue, child: Text('Вт')),
                          DropdownMenuItem(
                              value: WeekdayFilter.wed, child: Text('Ср')),
                          DropdownMenuItem(
                              value: WeekdayFilter.thu, child: Text('Чт')),
                          DropdownMenuItem(
                              value: WeekdayFilter.fri, child: Text('Пт')),
                          DropdownMenuItem(
                              value: WeekdayFilter.sat, child: Text('Сб')),
                          DropdownMenuItem(
                              value: WeekdayFilter.sun, child: Text('Вс')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                           await _prefs.setWeekdayFilter(value);
                           setState(() => _weekdayFilter = value);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Длина сессии',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<SessionLengthFilter>(
                        value: _lengthFilter,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: SessionLengthFilter.any,
                              child: Text('Любая')),
                          DropdownMenuItem(
                              value: SessionLengthFilter.oneToFive,
                              child: Text('1–5')),
                          DropdownMenuItem(
                              value: SessionLengthFilter.sixToTen,
                              child: Text('6–10')),
                          DropdownMenuItem(
                              value: SessionLengthFilter.elevenPlus,
                              child: Text('11+')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await _prefs.setLengthFilter(value);
                          setState(() => _lengthFilter = value);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Точность',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<AccuracyRange>(
                        value: _accuracyRange,
                        dropdownColor: AppColors.cardBackground,
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(
                              value: AccuracyRange.all, child: Text('Все')),
                          DropdownMenuItem(
                              value: AccuracyRange.lt50, child: Text('<50%')),
                          DropdownMenuItem(
                              value: AccuracyRange.pct50to75,
                              child: Text('50–75%')),
                          DropdownMenuItem(
                              value: AccuracyRange.pct75plus,
                              child: Text('>75%')),
                        ],
                        onChanged: (value) async {
                          if (value == null) return;
                          await _prefs.setAccuracyRange(value);
                          setState(() => _accuracyRange = value);
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Экспортировать только сессии с ≥ 3 тегами',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      Checkbox(
                        value: _exportTags3Only,
                        onChanged: (v) => _setExportTags3Only(v ?? false),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        key: TrainingHistoryScreen.exportCsvKey,
                        onPressed:
                            _getFilteredHistory().isEmpty ? null : _exportCsv,
                        child: const Text('Экспорт в CSV'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _getFilteredHistory().isEmpty
                            ? null
                            : _exportMarkdown,
                        child: const Text('Экспорт в MD'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            _getFilteredHistory().isEmpty ? null : _exportHtml,
                        child: const Text('Экспорт в HTML'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            _getFilteredHistory().isEmpty ? null : _exportPdf,
                        child: const Text('Экспорт в PDF'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _history.isEmpty ? null : _exportJson,
                        child: const Text('Экспорт JSON'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _importJson,
                        child: const Text('Импорт JSON'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickDateRange,
                        child: const Text('Фильтр по дате'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _dateFrom == null && _dateTo == null
                            ? null
                            : _clearDateFilter,
                        child: const Text('Сбросить дату'),
                      ),
                      const SizedBox(width: 8),
                      if (_dateFrom != null || _dateTo != null)
                        Text(
                          _dateRangeLabel(),
                          style: const TextStyle(color: Colors.white),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ToggleButtons(
                    isSelected: [
                      _dateFrom != null &&
                          DateUtils.isSameDay(
                              _dateFrom!,
                              DateUtils.dateOnly(DateTime.now()
                                  .subtract(const Duration(days: 6)))) &&
                          _dateTo != null &&
                          DateUtils.isSameDay(
                              _dateTo!, DateUtils.dateOnly(DateTime.now())),
                      _dateFrom != null &&
                          DateUtils.isSameDay(
                              _dateFrom!,
                              DateUtils.dateOnly(DateTime.now()
                                  .subtract(const Duration(days: 29)))) &&
                          _dateTo != null &&
                          DateUtils.isSameDay(
                              _dateTo!, DateUtils.dateOnly(DateTime.now())),
                      _dateFrom != null &&
                          DateUtils.isSameDay(
                              _dateFrom!,
                              DateUtils.dateOnly(DateTime.now()
                                  .subtract(const Duration(days: 89)))) &&
                          _dateTo != null &&
                          DateUtils.isSameDay(
                              _dateTo!, DateUtils.dateOnly(DateTime.now())),
                      _dateFrom == null && _dateTo == null,
                    ],
                    onPressed: (index) async {
                      switch (index) {
                        case 0:
                          await _applyQuickDateFilter(7);
                          break;
                        case 1:
                          await _applyQuickDateFilter(30);
                          break;
                        case 2:
                          await _applyQuickDateFilter(90);
                          break;
                        case 3:
                          await _clearDateFilter();
                          _loadHistory();
                          break;
                      }
                    },
                    borderRadius: BorderRadius.circular(4),
                    selectedColor: Colors.white,
                    fillColor: Colors.blueGrey,
                    color: Colors.white70,
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('7 дней'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('30 дней'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('90 дней'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('Все'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Builder(
                    builder: (context) {
                      final filtered = _getFilteredHistory();
                      final totalSessions = filtered.length;
                      final totalCorrect =
                          filtered.fold<int>(0, (sum, r) => sum + r.correct);
                      final avg = _calculateAverageAccuracy(filtered);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('Сессии: $totalSessions',
                                style: const TextStyle(color: Colors.white)),
                            Text('Верно: $totalCorrect',
                                style: const TextStyle(color: Colors.white)),
                            Text('Средняя: ${avg.toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                StreakSummary(
                  show: _history.isNotEmpty,
                  current: _calculateCurrentStreak(),
                  best: _calculateBestStreak(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Показать графики',
                          style: TextStyle(color: Colors.white)),
                      const Spacer(),
                      Switch(
                        value: _showCharts,
                        onChanged: _setChartsVisible,
                      ),
                    ],
                  ),
                ),
                if (_showCharts)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Тип графика',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        ToggleButtons(
                          isSelected: [
                            _chartMode == ChartMode.daily,
                            _chartMode == ChartMode.weekly,
                            _chartMode == ChartMode.monthly,
                          ],
                          onPressed: (index) =>
                              _setChartMode(ChartMode.values[index]),
                          borderRadius: BorderRadius.circular(4),
                          selectedColor: Colors.white,
                          fillColor: Colors.blueGrey,
                          color: Colors.white70,
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Дневной'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('Недельный'),
                            ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Месячный'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_showCharts)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _exportChartCsv,
                      child: const Text('Экспортировать график CSV'),
                    ),
                  ),
                ),
              if (_showCharts) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                      children: [
                        const Text('Показать график',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        Switch(
                          value: _showAvgChart,
                          onChanged: _setAvgChartVisible,
                        ),
                      ],
                    ),
                  ),
                  if (_showAvgChart) ...[
                  Builder(
                    builder: (context) {
                      final filtered = _getFilteredHistory();
                      final grouped = _groupSessionsForChart(filtered);
                      return AverageAccuracyChart(sessions: grouped);
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Показать распределение',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        Switch(
                          value: _showDistribution,
                          onChanged: _setDistributionVisible,
                        ),
                      ],
                    ),
                  ),
                  if (_showDistribution)
                    Builder(
                      builder: (context) {
                        final filtered = _getFilteredHistory();
                        final grouped = _groupSessionsForChart(filtered);
                        return AccuracyDistributionChart(sessions: grouped);
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Text('Показать тренд точности',
                            style: TextStyle(color: Colors.white)),
                        const Spacer(),
                        Switch(
                          value: _showTrendChart,
                          onChanged: _setTrendChartVisible,
                        ),
                      ],
                    ),
                  ),
                  if (_showTrendChart)
                    Builder(
                      builder: (context) {
                        final filtered = _getFilteredHistory();
                        final grouped = _groupSessionsForChart(filtered);
                        return AccuracyTrendChart(
                          sessions: grouped,
                          mode: ChartMode.values[_chartMode.index],
                        );
                      },
                    ),
                ],
              ],
              AverageAccuracySummary(
                accuracy: _calculateAverageAccuracy(_getFilteredHistory()),
              ),
              FilterSummary(
                summary: _getActiveFilterSummary(),
              ),
              Expanded(
                child: Builder(builder: (context) {
                    final filtered = _getFilteredHistory();
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final result = filtered[index];
                        return Dismissible(
                          key: ValueKey(result.date.toIso8601String()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Delete Session?'),
                                      content: const Text('Are you sure you want to delete this session?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                          },
                          onDismissed: (_) => _deleteSession(result),
                          child: HistoryListItem(
                            result: result,
                            onLongPress: () => _editSessionDate(result),
                            onTap: () => _editSessionComment(context, result),
                            onTagTap: () => _editSessionTags(context, result),
                            onDelete: () => _confirmDelete(result),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: filtered.length,
                    );
                  }),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Включить график в PDF',
                        style: TextStyle(color: Colors.white)),
                    const Spacer(),
                    Switch(
                      value: _includeChartInPdf,
                      onChanged: _setIncludeChartInPdf,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: _getFilteredHistory().isEmpty
                          ? null
                          : _copyVisibleResults,
                      child: const Text('Копировать результаты'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _getFilteredHistory().isEmpty
                          ? null
                          : _exportVisibleCsv,
                      child: const Text('Экспорт CSV'),
                    ),
                    const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _getFilteredHistory().isEmpty
                        ? null
                        : _exportVisiblePdf,
                    child: const Text('Экспорт PDF'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _exportProgressCsv(weekly: false),
                    child: const Text('Прогресс CSV'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _exportProgressPdf(weekly: false),
                    child: const Text('Прогресс PDF'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                    ElevatedButton(
                      onPressed: _openLatestExport,
                      child: const Text('Открыть'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _shareLatestExport,
                      child: const Text('Поделиться'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _deleteLatestExports,
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              ),
              ],
            ),
    );
  }
}
