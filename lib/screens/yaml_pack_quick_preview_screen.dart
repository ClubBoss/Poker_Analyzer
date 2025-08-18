import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/yaml_pack_preview_engine.dart';
import '../theme/app_colors.dart';
import 'yaml_viewer_screen.dart';

class YamlPackQuickPreviewScreen extends StatefulWidget {
  const YamlPackQuickPreviewScreen({super.key});

  @override
  State<YamlPackQuickPreviewScreen> createState() =>
      _YamlPackQuickPreviewScreenState();
}

class _YamlPackQuickPreviewScreenState
    extends State<YamlPackQuickPreviewScreen> {
  final List<(File, TrainingPackTemplateV2)> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dir = await getApplicationDocumentsDirectory();
    final libDir = Directory('${dir.path}/training_packs/library');
    const reader = YamlReader();
    final list = <(File, TrainingPackTemplateV2)>[];
    for (final f
        in libDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await f.readAsString();
        list.add((f, TrainingPackTemplateV2.fromYamlAuto(yaml)));
      } catch (_) {}
    }
    list.sort(
      (a, b) => b.$1.statSync().modified.compareTo(a.$1.statSync().modified),
    );
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  Future<void> _open(File file) async {
    final yaml = await file.readAsString();
    final name = file.path.split(Platform.pathSeparator).last;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YamlViewerScreen(yamlText: yaml, title: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    const engine = YamlPackPreviewEngine();
    return Scaffold(
      appBar: AppBar(title: const Text('Быстрый просмотр YAML')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final (file, pack) = _items[i];
                return GestureDetector(
                  onTap: () => _open(file),
                  child: engine.buildPreview(pack),
                );
              },
            ),
    );
  }
}
