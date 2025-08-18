import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

class YamlPackArchiveCleanupScreen extends StatefulWidget {
  const YamlPackArchiveCleanupScreen({super.key});

  @override
  State<YamlPackArchiveCleanupScreen> createState() =>
      _YamlPackArchiveCleanupScreenState();
}

class _YamlPackArchiveCleanupScreenState
    extends State<YamlPackArchiveCleanupScreen> {
  final Map<String, List<File>> _items = {};
  final TextEditingController _daysCtrl = TextEditingController(text: '30');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'training_packs', 'archive'));
    final map = <String, List<File>>{};
    if (await root.exists()) {
      for (final dir in root.listSync()) {
        if (dir is Directory) {
          final id = p.basename(dir.path);
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.bak.yaml'))
              .toList();
          if (files.isNotEmpty) map[id] = files;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(map);
      _loading = false;
    });
  }

  int _countAll() {
    var count = 0;
    for (final l in _items.values) {
      count += l.length;
    }
    return count;
  }

  String _sizeStr(List<File> files) {
    var size = 0;
    for (final f in files) {
      size += f.lengthSync();
    }
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteOld() async {
    final days = int.tryParse(_daysCtrl.text) ?? 30;
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final files = [
      for (final l in _items.values)
        ...l.where((f) => f.statSync().modified.isBefore(cutoff)),
    ];
    if (files.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Удалить ${files.length} файлов?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var deleted = 0;
    for (final f in files) {
      try {
        f.deleteSync();
        deleted++;
      } catch (_) {}
    }
    if (!mounted) return;
    await _load();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Удалено файлов: $deleted')));
  }

  Future<void> _deletePack(String id) async {
    final files = _items[id];
    if (files == null || files.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('Удалить архив $id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var deleted = 0;
    for (final f in files) {
      try {
        f.deleteSync();
        deleted++;
      } catch (_) {}
    }
    if (!mounted) return;
    await _load();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Удалено файлов: $deleted')));
  }

  Future<void> _clearAll() async {
    final count = _countAll();
    if (count == 0) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Очистить весь архив?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    var deleted = 0;
    for (final l in _items.values) {
      for (final f in l) {
        try {
          f.deleteSync();
          deleted++;
        } catch (_) {}
      }
    }
    if (!mounted) return;
    await _load();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Удалено файлов: $deleted')));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Очистка архива')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _daysCtrl,
                        decoration: const InputDecoration(labelText: 'Дней'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _deleteOld,
                      child: const Text('Удалить старые'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final e in _items.entries)
                  Card(
                    color: AppColors.cardBackground,
                    child: ListTile(
                      title: Text('${e.key} (${e.value.length})'),
                      subtitle: Text(_sizeStr(e.value)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deletePack(e.key),
                      ),
                    ),
                  ),
                if (_items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: _clearAll,
                      child: const Text('Очистить весь архив'),
                    ),
                  ),
              ],
            ),
    );
  }
}
