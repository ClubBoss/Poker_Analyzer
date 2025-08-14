import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart';
import '../helpers/date_utils.dart';
import '../helpers/accuracy_utils.dart';
import 'all_sessions/session_filter_bar.dart';
import 'all_sessions/session_list_item.dart';

import '../models/training_pack.dart';
import '../models/game_type.dart';
import 'session_detail_screen.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/responsive.dart';

class AllSessionsScreen extends StatefulWidget {
  const AllSessionsScreen({super.key});

  @override
  State<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _SessionEntry {
  final String packName;
  final String description;
  final TrainingSessionResult result;

  _SessionEntry(this.packName, this.description, this.result);
}

class _AllSessionsScreenState extends State<AllSessionsScreen> {
  final List<_SessionEntry> _allEntries = [];
  final List<_SessionEntry> _entries = [];
  final Set<String> _packNames = {};
  final Map<String, TrainingPack> _packs = {};
  String _filter = 'all';
  String _sortMode = 'date_desc';
  DateTimeRange? _dateRange;
  final TextEditingController _minPercentController = TextEditingController();
  final TextEditingController _maxPercentController = TextEditingController();
  double? _minPercent;
  double? _maxPercent;

  int _filteredCount = 0;
  double _averagePercent = 0;
  int _successCount = 0;
  int _failCount = 0;
  bool _showSummary = true;
  int _accuracyChartKey = 0;
  int _touchedAccuracyIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadHistory();
  }


  String _formatDay(DateTime d) => formatDate(d);

  String get _dateFilterText {
    if (_dateRange == null) return 'Все даты';
    final start = _formatDay(_dateRange!.start);
    final end = _formatDay(_dateRange!.end);
    return start == end ? start : '$start - $end';
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString('sessions_date_start');
    final endStr = prefs.getString('sessions_date_end');
    DateTimeRange? range;
    if (startStr != null && endStr != null) {
      final start = DateTime.tryParse(startStr);
      final end = DateTime.tryParse(endStr);
      if (start != null && end != null) {
        range = DateTimeRange(start: start, end: end);
      }
    }
    final sortPref = prefs.getString('sessions_sortMode');
    String sortMode;
    switch (sortPref) {
      case 'success_desc':
        sortMode = 'accuracy_desc';
        break;
      case 'success_asc':
        sortMode = 'accuracy_asc';
        break;
      case 'date_asc':
      case 'date_desc':
      case 'accuracy_desc':
      case 'accuracy_asc':
        sortMode = sortPref!;
        break;
      default:
        sortMode = 'date_desc';
    }
    setState(() {
      _filter = prefs.getString('sessions_filter') ?? 'all';
      _sortMode = sortMode;
      _dateRange = range;
      _minPercent = prefs.getDouble('sessions_percent_min');
      _maxPercent = prefs.getDouble('sessions_percent_max');
      _minPercentController.text =
          _minPercent != null ? _minPercent!.toStringAsFixed(0) : '';
      _maxPercentController.text =
          _maxPercent != null ? _maxPercent!.toStringAsFixed(0) : '';
      _showSummary = prefs.getBool('sessions_show_summary') ?? true;
    });
    _applyFilter();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessions_filter', _filter);
    await prefs.setString('sessions_sortMode', _sortMode);
    await prefs.setBool('sessions_show_summary', _showSummary);
    if (_dateRange != null) {
      await prefs.setString(
          'sessions_date_start', _dateRange!.start.toIso8601String());
      await prefs.setString(
          'sessions_date_end', _dateRange!.end.toIso8601String());
    } else {
      await prefs.remove('sessions_date_start');
      await prefs.remove('sessions_date_end');
    }
    if (_minPercent != null && _maxPercent != null) {
      await prefs.setDouble('sessions_percent_min', _minPercent!);
      await prefs.setDouble('sessions_percent_max', _maxPercent!);
    } else {
      await prefs.remove('sessions_percent_min');
      await prefs.remove('sessions_percent_max');
    }
  }

  Future<void> _loadHistory() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        final packs = [
          for (final item in data)
            if (item is Map<String, dynamic>)
              TrainingPack.fromJson(Map<String, dynamic>.from(item))
        ];
        final List<_SessionEntry> all = [];
        final Map<String, TrainingPack> loadedPacks = {
          for (final p in packs) p.name: p
        };
        for (final p in packs) {
          for (final r in p.history) {
            all.add(_SessionEntry(p.name, p.description, r));
          }
        }
        all.sort((a, b) => b.result.date.compareTo(a.result.date));
        final Set<String> names = {for (final p in packs) p.name};
        setState(() {
          _allEntries
            ..clear()
            ..addAll(all);
          _packNames
            ..clear()
            ..addAll(names);
          _packs
            ..clear()
            ..addAll(loadedPacks);
        });
        _applyFilter();
      }
    } catch (_) {}
  }

  void _applyFilter() {
    List<_SessionEntry> filtered;
    if (_filter == 'success') {
      filtered = _allEntries
          .where((e) =>
              e.result.total > 0 &&
              e.result.correct / e.result.total >= 0.7)
          .toList();
    } else if (_filter == 'fail') {
      filtered = _allEntries
          .where((e) =>
              e.result.total > 0 &&
              e.result.correct / e.result.total < 0.7)
          .toList();
    } else if (_filter.startsWith('pack:')) {
      final name = _filter.substring(5);
      filtered =
          _allEntries.where((e) => e.packName == name).toList();
    } else {
      filtered = List.from(_allEntries);
    }

    if (_dateRange != null) {
      filtered = filtered.where((e) {
        final d = e.result.date;
        return !d.isBefore(_dateRange!.start) && !d.isAfter(_dateRange!.end);
      }).toList();
    }

    if (_minPercent != null && _maxPercent != null) {
      filtered = filtered.where((e) {
        final percent = e.result.total > 0
            ? calculateAccuracy(e.result.correct, e.result.total)
            : 0.0;
        return percent >= _minPercent! && percent <= _maxPercent!;
      }).toList();
    }

    switch (_sortMode) {
      case 'date_asc':
        filtered.sort((a, b) => a.result.date.compareTo(b.result.date));
        break;
      case 'accuracy_desc':
      case 'success_desc': // backward compatibility
        filtered.sort((a, b) {
          final pa = a.result.total > 0
              ? a.result.correct / a.result.total
              : 0.0;
          final pb = b.result.total > 0
              ? b.result.correct / b.result.total
              : 0.0;
          return pb.compareTo(pa);
        });
        break;
      case 'accuracy_asc':
      case 'success_asc':
        filtered.sort((a, b) {
          final pa = a.result.total > 0
              ? a.result.correct / a.result.total
              : 0.0;
          final pb = b.result.total > 0
              ? b.result.correct / b.result.total
              : 0.0;
          return pa.compareTo(pb);
        });
        break;
      default: // 'date_desc'
        filtered.sort((a, b) => b.result.date.compareTo(a.result.date));
    }
    final int success = filtered
        .where((e) =>
            e.result.total > 0 &&
            e.result.correct / e.result.total >= 0.7)
        .length;
    final int fail = filtered
        .where((e) =>
            e.result.total > 0 &&
            e.result.correct / e.result.total < 0.7)
        .length;
    final double avg = filtered.isNotEmpty
        ? filtered
                .map((e) => e.result.total > 0
                    ? calculateAccuracy(e.result.correct, e.result.total)
                    : 0.0)
                .reduce((a, b) => a + b) /
            filtered.length
        : 0.0;
    setState(() {
      _entries
        ..clear()
        ..addAll(filtered);
      _filteredCount = filtered.length;
      _averagePercent = avg;
      _successCount = success;
      _failCount = fail;
    });
  }

  Future<void> _exportMarkdown() async {
    if (_entries.isEmpty) return;

    String title;
    if (_filter == 'all') {
      title = 'Все сессии';
    } else if (_filter == 'success') {
      title = 'Только успешные сессии';
    } else if (_filter == 'fail') {
      title = 'Только неуспешные сессии';
    } else if (_filter.startsWith('pack:')) {
      title = 'Пакет: ${_filter.substring(5)}';
    } else {
      title = _filter;
    }

    final buffer = StringBuffer()..writeln('## $title')..writeln();
    for (final e in _entries) {
      final percent = e.result.total > 0
          ? (calculateAccuracy(e.result.correct, e.result.total)).toStringAsFixed(0)
          : '0';
      buffer.writeln(
          '- ${e.packName} - ${formatDateTime(e.result.date)} - ${e.result.correct}/${e.result.total} ($percent%)');
    }

    final fileName =
        'sessions_${DateTime.now().millisecondsSinceEpoch}.md';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить Markdown',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['md'],
    );
    if (savePath == null) return;

    final file = File(savePath);
    await file.writeAsString(buffer.toString());

    if (mounted) {
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $name'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportCsv() async {
    if (_entries.isEmpty) return;

    final buffer = StringBuffer()
      ..writeln(
          'Date,Pack name,Correct answers,Total questions,Success percentage');
    for (final e in _entries) {
      final date = formatDateTime(e.result.date);
      final percent = e.result.total > 0
          ? (calculateAccuracy(e.result.correct, e.result.total)).round()
          : 0;
      buffer.writeln(
          '"$date","${e.packName}",${e.result.correct},${e.result.total},$percent');
    }

    final fileName =
        'sessions_${DateTime.now().millisecondsSinceEpoch}.csv';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить CSV',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (savePath == null) return;

    final file = File(savePath);
    await file.writeAsString(buffer.toString());

    if (mounted) {
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $name'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (_entries.isEmpty) return;

    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          final Map<String, List<_SessionEntry>> groups = {};
          for (final e in _entries) {
            groups.putIfAbsent(e.packName, () => []).add(e);
          }
          final List<String> names = groups.keys.toList()..sort();

          return [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Общее количество сессий:',
                        style: pw.TextStyle(font: boldFont)),
                    pw.SizedBox(width: 4),
                    pw.Text('$_filteredCount',
                        style: pw.TextStyle(font: regularFont)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Средний процент успешности:',
                        style: pw.TextStyle(font: boldFont)),
                    pw.SizedBox(width: 4),
                    pw.Text('${_averagePercent.toStringAsFixed(0)}%',
                        style: pw.TextStyle(font: regularFont)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Успешных сессий:',
                        style: pw.TextStyle(font: boldFont)),
                    pw.SizedBox(width: 4),
                    pw.Text('$_successCount',
                        style: pw.TextStyle(font: regularFont)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text('Неуспешных сессий:',
                        style: pw.TextStyle(font: boldFont)),
                    pw.SizedBox(width: 4),
                    pw.Text('$_failCount',
                        style: pw.TextStyle(font: regularFont)),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            ),
            for (final name in names) ...[
              pw.Text('Пакет: $name',
                  style: pw.TextStyle(font: boldFont)),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Дата',
                            style: pw.TextStyle(font: boldFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Название пакета',
                            style: pw.TextStyle(font: boldFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Правильных / Всего',
                            style: pw.TextStyle(font: boldFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Процент успешности',
                            style: pw.TextStyle(font: boldFont)),
                      ),
                    ],
                  ),
                  ...groups[name]!.map(
                    (e) {
                      final percent = e.result.total > 0
                          ? calculateAccuracy(e.result.correct, e.result.total)
                          : 0.0;
                      final color = percent >= 80
                          ? PdfColors.lightGreen
                          : percent >= 50
                              ? PdfColors.amber100
                              : PdfColors.red100;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(color: color),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              formatDateTime(e.result.date),
                              style: pw.TextStyle(font: regularFont),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              e.packName,
                              style: pw.TextStyle(font: regularFont),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${e.result.correct}/${e.result.total}',
                              style: pw.TextStyle(font: regularFont),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              e.result.total > 0
                                  ? '${(calculateAccuracy(e.result.correct, e.result.total)).toStringAsFixed(0)}%'
                                  : '0%',
                              style: pw.TextStyle(font: regularFont),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Название пакета',
                          style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Кол-во сессий',
                          style: pw.TextStyle(font: boldFont)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('Средний %',
                          style: pw.TextStyle(font: boldFont)),
                    ),
                  ],
                ),
                for (final name in names)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(name,
                            style: pw.TextStyle(font: regularFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('${groups[name]!.length}',
                            style: pw.TextStyle(font: regularFont)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          () {
                            var sum = 0.0;
                            for (final e in groups[name]!) {
                              sum += e.result.total > 0
                                  ? calculateAccuracy(e.result.correct, e.result.total)
                                  : 0.0;
                            }
                            final avg = sum / groups[name]!.length;
                            return '${avg.toStringAsFixed(0)}%';
                          }(),
                          style: pw.TextStyle(font: regularFont),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 20),
          ];
        },
      ),
    );

    final bytes = await pdf.save();

    final fileName =
        'sessions_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить PDF',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (savePath == null) return;

    final file = File(savePath);
    await file.writeAsBytes(bytes);

    if (mounted) {
      final name = savePath.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл сохранён: $name'),
          action: SnackBarAction(
            label: 'Открыть',
            onPressed: () {
              OpenFilex.open(file.path);
            },
          ),
        ),
      );
    }
  }

  Future<void> _deleteAllSessions() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все сессии?'),
        content: const Text(
            'Вы уверены, что хотите удалить все сессии? Это действие нельзя отменить'),
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
    if (confirm != true) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    if (await file.exists()) {
      await file.delete();
    }
    if (!mounted) return;

    _allEntries.clear();
    _packNames.clear();
    _packs.clear();
    _applyFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все сессии удалены')),
    );
  }

  Widget _buildAccuracyChart() {
    final sessions = _allEntries.take(30).toList();
    if (sessions.length < 2) {
      return const SizedBox.shrink();
    }
    sessions.sort((a, b) => a.result.date.compareTo(b.result.date));
    final spots = <FlSpot>[];
    for (var i = 0; i < sessions.length; i++) {
      final r = sessions[i].result;
      final percent = r.total > 0 ? r.correct * 100 / r.total : 0.0;
      spots.add(FlSpot(i.toDouble(), percent));
    }
    final step = (sessions.length / 6).ceil();
    final barData = LineChartBarData(
      spots: spots,
      color: Colors.white,
      barWidth: 2,
      isCurved: false,
      showingIndicators:
          _touchedAccuracyIndex != -1 ? [_touchedAccuracyIndex] : [],
      dotData: FlDotData(
        show: _touchedAccuracyIndex != -1,
        checkToShowDot: (spot, bar) =>
            bar.spots.indexOf(spot) == _touchedAccuracyIndex,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: Colors.yellow,
          strokeWidth: 0,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: Container(
          key: ValueKey(_accuracyChartKey),
          height: responsiveSize(context, 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2B2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: LineChart(
            LineChartData(
            minY: 0,
            maxY: 100,
            lineTouchData: LineTouchData(
              handleBuiltInTouches: false,
              touchCallback:
                  (FlTouchEvent event, LineTouchResponse? lineTouch) {
                if (!event.isInterestedForInteractions ||
                    lineTouch == null ||
                    lineTouch.lineBarSpots == null) {
                  setState(() {
                    _touchedAccuracyIndex = -1;
                  });
                  return;
                }
                setState(() {
                  _touchedAccuracyIndex =
                      lineTouch.lineBarSpots!.first.spotIndex;
                });
              },
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: Colors.black87,
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipItems: (spots) {
                  return spots.map((s) {
                    final entry = sessions[s.spotIndex];
                    final d = entry.result.date;
                    final date =
                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
                    final percent = s.y.toStringAsFixed(0);
                    return LineTooltipItem(
                      '$date\n${entry.packName}\n${entry.result.correct} из ${entry.result.total} ($percent%)',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  }).toList();
                },
              ),
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> indexes) {
                return indexes
                    .map((index) => TouchedSpotIndicatorData(
                          const FlLine(color: Colors.transparent),
                          FlDotData(
                            getDotPainter:
                                (spot, percent, bar, idx) =>
                                    FlDotCirclePainter(
                              radius: 4,
                              color: Colors.yellow,
                              strokeWidth: 0,
                            ),
                          ),
                        ))
                    .toList();
              },
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) =>
                  const FlLine(color: Colors.white24, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 20,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style:
                        const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= sessions.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % step != 0 && index != sessions.length - 1) {
                      return const SizedBox.shrink();
                    }
                    final d = sessions[index].result.date;
                    final label =
                        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
                    return Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10));
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: Colors.white24),
                bottom: BorderSide(color: Colors.white24),
              ),
            ),
            lineBarsData: [barData],
          ),
        ),
      ),
    );
  }

  Future<void> _renamePack(String oldName) async {
    final current = _allEntries.firstWhere(
      (e) => e.packName == oldName,
      orElse: () => _SessionEntry(oldName, '', TrainingSessionResult(date: DateTime.now(), total: 0, correct: 0)),
    );
    final nameController = TextEditingController(text: oldName);
    final descController = TextEditingController(text: current.description);
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать пакет'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Новое название'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Описание'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': nameController.text.trim(),
              'description': descController.text.trim(),
            }),
            child: const Text('Переименовать'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final newName = result['name'] ?? oldName;
    final newDescription = result['description'] ?? current.description;
    if (newName.isEmpty || (newName == oldName && newDescription == current.description)) return;

    final List<_SessionEntry> updatedAll = [
      for (final e in _allEntries)
        _SessionEntry(
          e.packName == oldName ? newName : e.packName,
          e.packName == oldName ? newDescription : e.description,
          e.result,
        )
    ];

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is List) {
          final List<TrainingPack> packs = [
            for (final item in data)
              if (item is Map<String, dynamic>)
                TrainingPack.fromJson(Map<String, dynamic>.from(item))
          ];
          final idx = packs.indexWhere((p) => p.name == oldName);
          if (idx != -1) {
            final p = packs[idx];
              packs[idx] = TrainingPack(
                name: newName,
                description: newDescription,
                category: p.category,
                gameType: p.gameType,
                colorTag: p.colorTag,
                tags: p.tags,
                hands: p.hands,
                spots: p.spots,
                difficulty: p.difficulty,
                history: p.history,
              );
            await file
                .writeAsString(jsonEncode([for (final p in packs) p.toJson()]));
          }
        }
      } catch (_) {}
    }

    setState(() {
      _allEntries
        ..clear()
        ..addAll(updatedAll);
      _packNames
        ..remove(oldName)
        ..add(newName);
      final oldPack = _packs.remove(oldName);
      if (oldPack != null) {
          _packs[newName] = TrainingPack(
            name: newName,
            description: newDescription,
            category: oldPack.category,
            gameType: oldPack.gameType,
            colorTag: oldPack.colorTag,
            tags: oldPack.tags,
            hands: oldPack.hands,
            spots: oldPack.spots,
            difficulty: oldPack.difficulty,
            history: oldPack.history,
          );
      }
    });
    _applyFilter();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пакет переименован')),
      );
    }
  }

  Future<void> _deletePack(String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить пакет «$name» и все его сессии?'),
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
    if (confirm != true) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    List<TrainingPack> packs = [];
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is List) {
          packs = [
            for (final item in data)
              if (item is Map<String, dynamic>)
                TrainingPack.fromJson(Map<String, dynamic>.from(item))
          ];
        }
      } catch (_) {}
    }
    packs.removeWhere((p) => p.name == name);
    await file.writeAsString(jsonEncode([for (final p in packs) p.toJson()]));

    setState(() {
      _allEntries.removeWhere((e) => e.packName == name);
      _packNames.remove(name);
      _packs.remove(name);
    });
    _applyFilter();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пакет удалён')),
      );
    }
  }

  Future<void> _showPackOptions(String name) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите действие'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'rename'),
            child: const Text('Переименовать'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (result == 'rename') {
      await _renamePack(name);
    } else if (result == 'delete') {
      await _deletePack(name);
    }
  }

  Future<void> _showPackPreview(_SessionEntry entry) async {
    TrainingPack? pack = _packs[entry.packName];
    if (pack == null) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/training_packs.json');
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          if (data is List) {
            for (final item in data) {
              if (item is Map<String, dynamic>) {
                final p =
                    TrainingPack.fromJson(Map<String, dynamic>.from(item));
                if (p.name == entry.packName) {
                  pack = p;
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }
    }
    if (pack == null) return;
    final avg = pack.history.isNotEmpty
        ? pack.history
                .map((r) => r.total > 0 ? r.correct * 100 / r.total : 0.0)
                .reduce((a, b) => a + b) /
            pack.history.length
        : 0.0;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pack.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pack.description.isNotEmpty) Text(pack.description),
            const SizedBox(height: 8),
            Text('Категория: ${pack.category}'),
            Text('Тип: ${pack.gameType.label}'),
            Text('Кол-во рук: ${pack.hands.length}'),
            Text('Всего сессий: ${pack.history.length}'),
            Text('Средний % верных: ${avg.toStringAsFixed(0)}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(
                    packName: entry.packName,
                    result: entry.result,
                  ),
                ),
              );
            },
            child: const Text('Открыть последнюю сессию'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = _dateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: initialRange,
    );
    if (picked != null) {
      _dateRange = picked;
      _savePreferences();
      _applyFilter();
    }
  }

  void _resetFilters() {
    _filter = 'all';
    _dateRange = null;
    _sortMode = 'date_desc';
    _minPercent = null;
    _maxPercent = null;
    _minPercentController.text = '';
    _maxPercentController.text = '';
    _savePreferences();
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('История тренировок'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Column(
        children: [
          if (_allEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SessionFilterBar(
                filter: _filter,
                packNames: _packNames,
                onFilterChanged: (value) {
                  if (value != null) {
                    setState(() => _filter = value);
                    _savePreferences();
                    _applyFilter();
                  }
                },
                onPickDateRange: _pickDateRange,
                dateFilterText: _dateFilterText,
                sortMode: _sortMode,
                onSortChanged: (value) {
                  if (value != null) {
                    setState(() => _sortMode = value);
                    _savePreferences();
                    _applyFilter();
                  }
                },
                onReset: _resetFilters,
              ),
            ),
          if (_allEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _minPercentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Min %',
                      ),
                      onChanged: (v) {
                        final val = double.tryParse(v);
                        _minPercent = val;
                        _savePreferences();
                        _applyFilter();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _maxPercentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Max %',
                      ),
                      onChanged: (v) {
                        final val = double.tryParse(v);
                        _maxPercent = val;
                        _savePreferences();
                        _applyFilter();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _minPercentController.text = '';
                      _maxPercentController.text = '';
                      _minPercent = null;
                      _maxPercent = null;
                      _savePreferences();
                      _applyFilter();
                    },
                    icon: const Icon(Icons.close),
                    tooltip: 'Сбросить диапазон',
                  ),
                ],
              ),
            ),
          if (_allEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _showSummary
                  ? Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2B2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Сессий: $_filteredCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Успешных: $_successCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Неуспешных: $_failCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Средний %: ${_averagePercent.toStringAsFixed(0)}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.visibility),
                            color: Colors.white70,
                          onPressed: () {
                            setState(() {
                              _showSummary = false;
                              _accuracyChartKey++;
                            });
                            _savePreferences();
                          },
                          ),
                        ),
                      ],
                    )
                  : Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.visibility_off),
                        color: Colors.white70,
                        onPressed: () {
                          setState(() {
                            _showSummary = true;
                            _accuracyChartKey++;
                          });
                          _savePreferences();
                        },
                    ),
                ),
            ),
          if (_showSummary && _allEntries.length >= 2)
            _buildAccuracyChart(),
          if (_entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _exportMarkdown,
                      child: const Text('Экспортировать в Markdown'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _exportCsv,
                      child: const Text('Export to CSV'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _exportPdf,
                      child: const Text('Export to PDF'),
                    ),
                  ),
                ],
              ),
            ),
          if (_allEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: _deleteAllSessions,
                  child: const Text('Удалить все сессии'),
                ),
              ),
            ),
          Expanded(
            child: _entries.isEmpty
                ? const Center(
                    child: Text('История пуста'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final e = _entries[index];
                      return SessionListItem(
                        packName: e.packName,
                        description: e.description,
                        result: e.result,
                        onTap: () => _showPackPreview(e),
                        onShowOptions: () => _showPackOptions(e.packName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _minPercentController.dispose();
    _maxPercentController.dispose();
    super.dispose();
  }
}
