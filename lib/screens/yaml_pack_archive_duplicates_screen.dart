import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../utils/snackbar_util.dart';

class YamlPackArchiveDuplicatesScreen extends StatefulWidget {
  const YamlPackArchiveDuplicatesScreen({super.key});

  @override
  State<YamlPackArchiveDuplicatesScreen> createState() => _YamlPackArchiveDuplicatesScreenState();
}

class _YamlPackArchiveDuplicatesScreenState extends State<YamlPackArchiveDuplicatesScreen> {
  bool _loading = true;
  final Map<String, Map<String, List<File>>> _items = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await compute(_scanTask, '');
    if (!mounted) return;
    final map = <String, Map<String, List<File>>>{};
    for (final e in data.entries) {
      map[e.key] = {for (final g in e.value.entries) g.key: [for (final pth in g.value) File(pth)]};
    }
    setState(() {
      _items
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  Future<void> _deleteGroup(String id, String hash) async {
    final files = _items[id]?[hash];
    if (files == null || files.length <= 1) return;
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    final keep = files.first;
    int deleted = 0;
    for (final f in files.skip(1)) {
      try { f.deleteSync(); deleted++; } catch (_) {}
    }
    await _load();
    if (mounted && deleted > 0) {
      SnackbarUtil.showMessage(context, 'Удалено файлов: $deleted');
    }
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Удалить все дубликаты?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Нет')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Да')),
        ],
      ),
    );
    if (ok != true) return;
    int deleted = 0;
    for (final map in _items.values) {
      for (final files in map.values) {
        if (files.length <= 1) continue;
        files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        for (final f in files.skip(1)) {
          try { f.deleteSync(); deleted++; } catch (_) {}
        }
      }
    }
    await _load();
    if (mounted && deleted > 0) {
      SnackbarUtil.showMessage(context, 'Удалено файлов: $deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Дубликаты архива'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in _items.entries)
                  ExpansionTile(
                    title: Text(e.key),
                    children: [
                      for (final g in e.value.entries)
                        if (g.value.length > 1)
                          Card(
                            color: AppColors.cardBackground,
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text('${g.key.substring(0, 8)} (${g.value.length})'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _deleteGroup(e.key, g.key),
                                  ),
                                ),
                                for (final f in g.value)
                                  ListTile(
                                    title: Text(p.basename(f.path)),
                                    subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(f.statSync().modified)),
                                  ),
                              ],
                            ),
                          ),
                    ],
                  ),
                if (_items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: _deleteAll,
                      child: const Text('🗑 Удалить все дубликаты'),
                    ),
                  ),
              ],
            ),
    );
  }
}

Future<Map<String, Map<String, List<String>>>> _scanTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final root = Directory(p.join(docs.path, 'training_packs', 'archive'));
  final result = <String, Map<String, List<String>>>{};
  if (root.existsSync()) {
    for (final dir in root.listSync()) {
      if (dir is Directory) {
        final id = p.basename(dir.path);
        final map = <String, List<String>>{};
        for (final f in dir.listSync()) {
          if (f is File && f.path.endsWith('.bak.yaml')) {
            final bytes = await f.readAsBytes();
            final hash = md5.convert(bytes).toString();
            map.putIfAbsent(hash, () => []).add(f.path);
          }
        }
        final dup = <String, List<String>>{};
        map.forEach((k, v) {
          if (v.length > 1) dup[k] = v;
        });
        if (dup.isNotEmpty) result[id] = dup;
      }
    }
  }
  return result;
}
