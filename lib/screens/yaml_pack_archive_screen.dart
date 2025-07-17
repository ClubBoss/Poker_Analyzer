import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import 'yaml_viewer_screen.dart';
import 'yaml_pack_diff_screen.dart';
import '../services/yaml_pack_diff_service.dart';
import '../widgets/markdown_preview_dialog.dart';
import '../services/yaml_pack_changelog_service.dart';

class YamlPackArchiveScreen extends StatefulWidget {
  const YamlPackArchiveScreen({super.key});

  @override
  State<YamlPackArchiveScreen> createState() => _YamlPackArchiveScreenState();
}

class _YamlPackArchiveScreenState extends State<YamlPackArchiveScreen> {
  final Map<String, List<File>> _items = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory('${docs.path}/training_packs/archive');
    final map = <String, List<File>>{};
    if (await root.exists()) {
      for (final dir in root.listSync()) {
        if (dir is Directory) {
          final id = p.basename(dir.path);
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.bak.yaml'))
              .toList()
            ..sort((a, b) =>
                b.statSync().modified.compareTo(a.statSync().modified));
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

  Future<void> _open(String id, File file) async {
    final yaml = await file.readAsString();
    late TrainingPackTemplateV2 bak;
    try {
      bak = TrainingPackTemplateV2.fromYaml(yaml);
    } catch (_) {
      return;
    }
    final path = bak.meta['path']?.toString();
    TrainingPackTemplateV2? current;
    if (path != null && path.isNotEmpty) {
      final f = File(path);
      if (await f.exists()) {
        try {
          final y = await f.readAsString();
          current = TrainingPackTemplateV2.fromYaml(y);
        } catch (_) {}
      }
    }
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(id),
        actions: [
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'diff'),
              child: const Text('Сравнить'),
            ),
          if (current != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'md'),
              child: const Text('📊 Сравнить с текущим'),
            ),
          if (path != null && path.isNotEmpty)
            TextButton(
              onPressed: () => Navigator.pop(context, 'restore'),
              child: const Text('Восстановить'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'copy'),
            child: const Text('Открыть копию'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'diff' && current != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => YamlPackDiffScreen(packA: bak, packB: current!),
        ),
      );
    } else if (action == 'md' && current != null) {
      final md = const YamlPackDiffService()
          .generateMarkdownDiff(bak, current!);
      if (md.isNotEmpty && mounted) {
        await showMarkdownPreviewDialog(context, md);
      }
    } else if (action == 'restore' && path != null && path.isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text('Подтверждение'),
          content: const Text('Восстановить пак из архива?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (ok == true) {
        await File(path).writeAsString(yaml);
        await const YamlPackChangelogService().appendChangeLog(
          bak,
          'восстановление из архива ${DateTime.now().toIso8601String()}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Пак успешно восстановлен из архива')),
          );
        }
      }
    } else if (action == 'copy') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              YamlViewerScreen(yamlText: yaml, title: '${id}_copy'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Архив паков')),
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final e in _items.entries)
                  ExpansionTile(
                    title: Text(e.key),
                    children: [
                      for (final f in e.value)
                        ListTile(
                          title: Text(DateFormat('yyyy-MM-dd HH:mm')
                              .format(f.statSync().modified)),
                          subtitle: Text(
                              '${(f.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                          onTap: () => _open(e.key, f),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}
