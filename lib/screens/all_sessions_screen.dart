import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/training_pack.dart';
import 'session_detail_screen.dart';

class AllSessionsScreen extends StatefulWidget {
  const AllSessionsScreen({super.key});

  @override
  State<AllSessionsScreen> createState() => _AllSessionsScreenState();
}

class _SessionEntry {
  final String packName;
  final TrainingSessionResult result;
  _SessionEntry(this.packName, this.result);
}

class _AllSessionsScreenState extends State<AllSessionsScreen> {
  final List<_SessionEntry> _allEntries = [];
  final List<_SessionEntry> _entries = [];
  final Set<String> _packNames = {};
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

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadHistory();
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day.$month.$year $hour:$minute';
  }

  String _formatDay(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year.toString();
    return '$day.$month.$year';
  }

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
    setState(() {
      _filter = prefs.getString('sessions_filter') ?? 'all';
      _sortMode = prefs.getString('sessions_sortMode') ?? 'date_desc';
      _dateRange = range;
      _minPercent = prefs.getDouble('sessions_percent_min');
      _maxPercent = prefs.getDouble('sessions_percent_max');
      _minPercentController.text =
          _minPercent != null ? _minPercent!.toStringAsFixed(0) : '';
      _maxPercentController.text =
          _maxPercent != null ? _maxPercent!.toStringAsFixed(0) : '';
    });
    _applyFilter();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessions_filter', _filter);
    await prefs.setString('sessions_sortMode', _sortMode);
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
        for (final p in packs) {
          for (final r in p.history) {
            all.add(_SessionEntry(p.name, r));
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
            ? e.result.correct * 100 / e.result.total
            : 0.0;
        return percent >= _minPercent! && percent <= _maxPercent!;
      }).toList();
    }

    switch (_sortMode) {
      case 'date_asc':
        filtered.sort((a, b) => a.result.date.compareTo(b.result.date));
        break;
      case 'success_desc':
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
      case 'pack_az':
        filtered.sort((a, b) => a.packName.compareTo(b.packName));
        break;
      case 'pack_za':
        filtered.sort((a, b) => b.packName.compareTo(a.packName));
        break;
      default:
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
                    ? e.result.correct * 100 / e.result.total
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
          ? (e.result.correct * 100 / e.result.total).toStringAsFixed(0)
          : '0';
      buffer.writeln(
          '- ${e.packName} — ${_formatDate(e.result.date)} — ${e.result.correct}/${e.result.total} (${percent}%)');
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
              OpenFile.open(file.path);
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
      final date = _formatDate(e.result.date);
      final percent = e.result.total > 0
          ? (e.result.correct * 100 / e.result.total).round()
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
              OpenFile.open(file.path);
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
              pw.Table.fromTextArray(
                headers: const [
                  'Дата',
                  'Название пакета',
                  'Правильных / Всего',
                  'Процент успешности'
                ],
                headerStyle: pw.TextStyle(font: boldFont),
                cellStyle: pw.TextStyle(font: regularFont),
                data: [
                  for (final e in groups[name]!)
                    [
                      _formatDate(e.result.date),
                      e.packName,
                      '${e.result.correct}/${e.result.total}',
                      e.result.total > 0
                          ? '${(e.result.correct * 100 / e.result.total).toStringAsFixed(0)}%'
                          : '0%'
                    ]
                ],
              ),
              pw.SizedBox(height: 20),
            ]
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
              OpenFile.open(file.path);
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
    _applyFilter();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все сессии удалены')),
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
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Column(
        children: [
          if (_allEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: _filter,
                      dropdownColor: const Color(0xFF2A2B2E),
                      style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value != null) {
                        _filter = value;
                        _savePreferences();
                        _applyFilter();
                      }
                    },
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('Все сессии'),
                        ),
                        const DropdownMenuItem(
                          value: 'success',
                          child: Text('Только успешные (>70%)'),
                        ),
                        const DropdownMenuItem(
                          value: 'fail',
                          child: Text('Только неуспешные (<70%)'),
                        ),
                        if (_packNames.length > 1)
                          ...[
                            for (final name in _packNames)
                              DropdownMenuItem(
                                value: 'pack:$name',
                                child: Text('Пакет: $name'),
                              )
                          ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _pickDateRange,
                    child: Text(_dateFilterText),
                  ),
                  const SizedBox(width: 8),
                  const Text('Sort by:', style: TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _sortMode,
                    dropdownColor: const Color(0xFF2A2B2E),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value != null) {
                        _sortMode = value;
                        _savePreferences();
                        _applyFilter();
                      }
                    },
                    items: const [
                      DropdownMenuItem(
                        value: 'date_desc',
                        child: Text('Date ↓'),
                      ),
                      DropdownMenuItem(
                        value: 'date_asc',
                        child: Text('Date ↑'),
                      ),
                      DropdownMenuItem(
                        value: 'success_desc',
                        child: Text('Success ↓'),
                      ),
                      DropdownMenuItem(
                        value: 'success_asc',
                        child: Text('Success ↑'),
                      ),
                      DropdownMenuItem(
                        value: 'pack_az',
                        child: Text('Pack A–Z'),
                      ),
                      DropdownMenuItem(
                        value: 'pack_za',
                        child: Text('Pack Z–A'),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.clear),
                    tooltip: 'Сбросить',
                  )
                ],
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Сессий: $_filteredCount',
                      style: const TextStyle(color: Colors.white)),
                  Text('Средний %: ${_averagePercent.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white)),
                  Text('Успешных: $_successCount, Неуспешных: $_failCount',
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
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
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(
                                packName: e.packName,
                                result: e.result,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2B2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.packName,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(e.result.date),
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${e.result.correct}/${e.result.total}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e.result.total > 0
                                      ? '${(e.result.correct * 100 / e.result.total).toStringAsFixed(0)}%'
                                      : '0%',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
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
