import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../models/v2/training_pack_template.dart';
import '../helpers/training_pack_storage.dart';
import '../helpers/training_pack_validator.dart';
import 'v2/training_pack_template_list_screen.dart';

class PackBundleInfo {
  final String path;
  final TrainingPackTemplate template;
  PackBundleInfo(this.path, this.template);
}

class PackBundleViewerScreen extends StatefulWidget {
  const PackBundleViewerScreen({super.key});

  @override
  State<PackBundleViewerScreen> createState() => _PackBundleViewerScreenState();
}

class _PackBundleViewerScreenState extends State<PackBundleViewerScreen> {
  final List<PackBundleInfo> _bundles = [];

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
        allowMultiple: true, type: FileType.custom, allowedExtensions: ['pka']);
    if (result == null) return;
    final items = <PackBundleInfo>[];
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      try {
        final data = await File(path).readAsBytes();
        final archive = ZipDecoder().decodeBytes(data);
        final tplFile =
            archive.files.firstWhere((e) => e.name == 'template.json');
        final json =
            jsonDecode(utf8.decode(tplFile.content)) as Map<String, dynamic>;
        final tpl = TrainingPackTemplate.fromJson(json);
        items.add(PackBundleInfo(path, tpl));
      } catch (_) {}
    }
    items.sort((a, b) {
      final ad =
          a.template.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd =
          b.template.lastGeneratedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = bd.compareTo(ad);
      if (cmp != 0) return cmp;
      final aa = (a.template.evCovered + a.template.icmCovered) / 2;
      final bb = (b.template.evCovered + b.template.icmCovered) / 2;
      return bb.compareTo(aa);
    });
    setState(() {
      _bundles
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _install(PackBundleInfo info) async {
    final listState = TrainingPackTemplateListScreen.maybeOf(context);
    final messenger = ScaffoldMessenger.maybeOf(listState?.context ?? context);
    final List<TrainingPackTemplate> templates =
        await TrainingPackStorage.load();
    final idx = templates.indexWhere((t) => t.id == info.template.id);
    final identical =
        idx != -1 && templates[idx].createdAt == info.template.createdAt;
    if (identical) return;
    if (idx != -1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Перезаписать существующий пак?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Yes')),
          ],
        ),
      );
      if (confirm != true) return;
      templates.removeAt(idx);
    }
    final issues = validateTrainingPackTemplate(info.template);
    if (issues.isNotEmpty) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Ошибка: ${issues.join(', ')}')),
      );
      return;
    }
    templates.add(info.template);
    await TrainingPackStorage.save(templates);
    messenger?.showSnackBar(const SnackBar(content: Text('Пак установлен')));
    Navigator.pop(context); // sheet
    Navigator.pop(context); // screen
    listState?.refreshFromStorage();
  }

  void _showBundleInfo(PackBundleInfo info) async {
    final templates = await TrainingPackStorage.load();
    final existing =
        templates.firstWhereOrNull((e) => e.id == info.template.id);
    final identical =
        existing != null && existing.createdAt == info.template.createdAt;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final t = info.template;
        final total = t.spots.length;
        final evPct = total == 0 ? 0 : (t.evCovered * 100 / total).round();
        final icmPct = total == 0 ? 0 : (t.icmCovered * 100 / total).round();
        Color color(int v) => v < 70
            ? Colors.red
            : v < 90
                ? Colors.yellow[700]!
                : Colors.green;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.name,
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
              if (t.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(t.description,
                      style: const TextStyle(color: Colors.white70)),
                ),
              const SizedBox(height: 8),
              Text('Спотов: $total',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Chip(
                    label: Text('EV $evPct%'),
                    backgroundColor: color(evPct),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('ICM $icmPct%'),
                    backgroundColor: color(icmPct),
                  ),
                ],
              ),
              if (t.lastGeneratedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Сгенерирован: ${t.lastGeneratedAt!.toLocal().toString().split('.').first}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: identical ? null : () => _install(info),
                    child: const Text('Установить'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bundle Viewer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
                onPressed: _pick, child: const Text('Select Bundles')),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _bundles.length,
              itemBuilder: (_, i) {
                final b = _bundles[i];
                final tpl = b.template;
                final coverage = (tpl.evCovered + tpl.icmCovered) / 2;
                final date = tpl.lastGeneratedAt;
                return ListTile(
                  title: Text(tpl.name),
                  subtitle: Text([
                    if (date != null)
                      date.toLocal().toString().split('.').first,
                    '${coverage.round()}%'
                  ].join(' · ')),
                  onTap: () => _showBundleInfo(b),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
