import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';

import '../models/training_pack.dart';

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

  @override
  void initState() {
    super.initState();
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
    setState(() {
      _entries
        ..clear()
        ..addAll(filtered);
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
              child: DropdownButton<String>(
                value: _filter,
                dropdownColor: const Color(0xFF2A2B2E),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (value != null) {
                    _filter = value;
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
          if (_entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _exportMarkdown,
                child: const Text('Экспортировать в Markdown'),
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
                      return Container(
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
}
