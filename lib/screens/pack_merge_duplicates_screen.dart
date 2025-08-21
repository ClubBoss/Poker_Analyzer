import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/yaml_pack_conflict_detector.dart';
import '../services/yaml_pack_merge_engine.dart';
import '../theme/app_colors.dart';
import '../ui/tools/training_pack_yaml_previewer.dart';

class PackMergeDuplicatesScreen extends StatefulWidget {
  const PackMergeDuplicatesScreen({super.key});
  @override
  State<PackMergeDuplicatesScreen> createState() =>
      _PackMergeDuplicatesScreenState();
}

class _PackMergeDuplicatesScreenState extends State<PackMergeDuplicatesScreen> {
  bool _loading = true;
  final List<YamlPackConflict> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await compute(_conflictTask, '');
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(data);
      _loading = false;
    });
  }

  Future<void> _merge(YamlPackConflict c) async {
    final merged = const YamlPackMergeEngine().merge(c.packA, c.packB);
    await showTrainingPackYamlPreviewer(context, merged);
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.background,
        title: const Text('Сохранить?'),
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
    await compute(_saveTask, merged.toJson());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Шаблон сохранён')));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Объединение дубликатов')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ElevatedButton(
                  onPressed: _load,
                  child: const Text('🔄 Обновить'),
                ),
                const SizedBox(height: 16),
                for (final c in _items)
                  ListTile(
                    title: Text('${c.packA.name} ↔ ${c.packB.name}'),
                    subtitle: Text(
                      '${c.type} ${(c.similarityScore * 100).toStringAsFixed(0)}%',
                    ),
                    onTap: () => _merge(c),
                  ),
              ],
            ),
    );
  }
}

Future<List<YamlPackConflict>> _conflictTask(String _) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/training_packs/library');
  if (!dir.existsSync()) return [];
  const reader = YamlReader();
  final packs = <TrainingPackTemplateV2>[];
  for (final f in dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
    try {
      final yaml = await f.readAsString();
      packs.add(TrainingPackTemplateV2.fromYamlAuto(yaml));
    } catch (_) {}
  }
  final res = const YamlPackConflictDetector().detectConflicts(packs);
  return [
    for (final c in res)
      if (c.type.startsWith('duplicate_') || c.similarityScore > 0.9) c,
  ];
}

Future<void> _saveTask(Map<String, dynamic> json) async {
  final tpl = TrainingPackTemplateV2.fromJson(json);
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/training_packs/library');
  await dir.create(recursive: true);
  final path = '${dir.path}/${tpl.id}.yaml';
  await const YamlWriter().write(tpl.toJson(), path);
}
