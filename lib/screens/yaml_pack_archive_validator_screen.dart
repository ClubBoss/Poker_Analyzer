import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';

class YamlPackArchiveValidatorScreen extends StatefulWidget {
  const YamlPackArchiveValidatorScreen({super.key});

  @override
  State<YamlPackArchiveValidatorScreen> createState() =>
      _YamlPackArchiveValidatorScreenState();
}

class _YamlPackArchiveValidatorScreenState
    extends State<YamlPackArchiveValidatorScreen> {
  bool _loading = true;
  final List<_ErrorEntry> _errors = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await compute(_validateTask, '');
    if (!mounted) return;
    setState(() {
      _errors
        ..clear()
        ..addAll(
          data.map(
            (e) => _ErrorEntry(
              path: e['path'] as String,
              error: e['error'] as String,
              time: DateTime.fromMillisecondsSinceEpoch(e['time'] as int),
            ),
          ),
        );
      _loading = false;
    });
  }

  String _fileName(String path) => p.basename(path);

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Валидатор YAML-паков'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in _errors)
                  Card(
                    color: AppColors.cardBackground,
                    child: ListTile(
                      title: Text(_fileName(e.path)),
                      subtitle: Text(
                        '${DateFormat('yyyy-MM-dd HH:mm').format(e.time)}\n${e.path}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        e.error,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                if (_errors.isEmpty)
                  const Center(child: Text('Ошибок не найдено')),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ElevatedButton(
                    onPressed: _load,
                    child: const Text('🧪 Проверить все архивы'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ErrorEntry {
  final String path;
  final String error;
  final DateTime time;
  const _ErrorEntry({
    required this.path,
    required this.error,
    required this.time,
  });
}

Future<List<Map<String, dynamic>>> _validateTask(String _) async {
  bool versionLess(String? v) {
    if (v == null || v.isEmpty) return true;
    final a = v.split('.').map(int.parse).toList();
    final b = '2.0.0'.split('.').map(int.parse).toList();
    while (a.length < 3) {
      a.add(0);
    }
    while (b.length < 3) {
      b.add(0);
    }
    for (var i = 0; i < 3; i++) {
      if (a[i] < b[i]) return true;
      if (a[i] > b[i]) return false;
    }
    return false;
  }

  final docs = await getApplicationDocumentsDirectory();
  final root = Directory(p.join(docs.path, 'training_packs', 'archive'));
  final res = <Map<String, dynamic>>[];
  if (root.existsSync()) {
    for (final dir in root.listSync()) {
      if (dir is Directory) {
        for (final f in dir.listSync()) {
          if (f is File && f.path.endsWith('.bak.yaml')) {
            final stat = f.statSync();
            String? err;
            try {
              final content = await f.readAsString();
              final tpl = TrainingPackTemplateV2.fromYamlAuto(content);
              final v = tpl.meta['schemaVersion']?.toString();
              if (versionLess(v)) err = 'outdated';
            } on FormatException catch (_) {
              err = 'FormatException';
            } on YamlException catch (_) {
              err = 'YamlException';
            } catch (e) {
              err = e.runtimeType.toString();
            }
            if (err != null) {
              res.add({
                'path': f.path,
                'error': err,
                'time': stat.modified.millisecondsSinceEpoch,
              });
            }
          }
        }
      }
    }
  }
  res.sort((a, b) => (b['time'] as int).compareTo(a['time'] as int));
  return res;
}
