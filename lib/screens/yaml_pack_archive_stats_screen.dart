import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

class YamlPackArchiveStatsScreen extends StatefulWidget {
  const YamlPackArchiveStatsScreen({super.key});

  @override
  State<YamlPackArchiveStatsScreen> createState() =>
      _YamlPackArchiveStatsScreenState();
}

class _PackStat {
  final int count;
  final int size;
  final DateTime first;
  final DateTime last;
  const _PackStat(this.count, this.size, this.first, this.last);
}

class _YamlPackArchiveStatsScreenState
    extends State<YamlPackArchiveStatsScreen> {
  bool _loading = true;
  final Map<String, _PackStat> _stats = {};
  int _totalFiles = 0;
  int _totalSize = 0;
  String _sort = 'id';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await compute(_statsTask, '');
    if (!mounted) return;
    final map = <String, _PackStat>{};
    for (final e in (res['stats'] as Map).entries) {
      map[e.key] = _PackStat(
        e.value['count'] as int,
        e.value['size'] as int,
        DateTime.fromMillisecondsSinceEpoch(e.value['first'] as int),
        DateTime.fromMillisecondsSinceEpoch(e.value['last'] as int),
      );
    }
    setState(() {
      _stats
        ..clear()
        ..addAll(map);
      _totalFiles = res['totalFiles'] as int? ?? 0;
      _totalSize = res['totalSize'] as int? ?? 0;
      _loading = false;
    });
  }

  String _sizeStr(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  List<MapEntry<String, _PackStat>> _sorted() {
    final list = _stats.entries.toList();
    switch (_sort) {
      case 'date':
        list.sort((a, b) => b.value.last.compareTo(a.value.last));
        break;
      case 'size':
        list.sort((a, b) => b.value.size.compareTo(a.value.size));
        break;
      default:
        list.sort((a, b) => a.key.compareTo(b.key));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика архива'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => setState(() => _sort = 'id'),
                child: Text('ID',
                    style: TextStyle(
                        color: _sort == 'id' ? Colors.amber : Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => _sort = 'date'),
                child: Text('Дата',
                    style: TextStyle(
                        color: _sort == 'date' ? Colors.amber : Colors.white)),
              ),
              TextButton(
                onPressed: () => setState(() => _sort = 'size'),
                child: Text('Размер',
                    style: TextStyle(
                        color: _sort == 'size' ? Colors.amber : Colors.white)),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Файлы'), numeric: true),
                      DataColumn(label: Text('Размер'), numeric: true),
                      DataColumn(label: Text('Диапазон')),
                    ],
                    rows: [
                      for (final e in _sorted())
                        DataRow(cells: [
                          DataCell(Text(e.key)),
                          DataCell(Text('${e.value.count}')),
                          DataCell(Text(_sizeStr(e.value.size))),
                          DataCell(Text(
                              '${DateFormat('yyyy-MM-dd').format(e.value.first)} - ${DateFormat('yyyy-MM-dd').format(e.value.last)}')),
                        ]),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                    '📊 Архив: $_totalFiles файлов, ${_sizeStr(_totalSize)}, ${_stats.length} паков'),
              ],
            ),
    );
  }
}

Future<Map<String, dynamic>> _statsTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory(p.join(docs.path, 'training_packs', 'archive'));
  final res = <String, Map<String, dynamic>>{};
  int totalFiles = 0;
  int totalSize = 0;
  if (root.existsSync()) {
    for (final dir in root.listSync()) {
      if (dir is Directory) {
        final id = p.basename(dir.path);
        int count = 0;
        int size = 0;
        DateTime? first;
        DateTime? last;
        for (final f in dir.listSync()) {
          if (f is File && f.path.endsWith('.bak.yaml')) {
            final stat = f.statSync();
            count++;
            size += stat.size;
            final m = stat.modified;
            first = first == null || m.isBefore(first) ? m : first;
            last = last == null || m.isAfter(last) ? m : last;
          }
        }
        if (count > 0 && first != null && last != null) {
          res[id] = {
            'count': count,
            'size': size,
            'first': first.millisecondsSinceEpoch,
            'last': last.millisecondsSinceEpoch,
          };
          totalFiles += count;
          totalSize += size;
        }
      }
    }
  }
  return {'stats': res, 'totalFiles': totalFiles, 'totalSize': totalSize};
}
