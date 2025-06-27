import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import '../helpers/color_utils.dart';
import '../models/training_pack_template.dart';
import '../services/training_pack_storage_service.dart';
import 'pack_editor_screen.dart';

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState extends State<TrainingPackTemplateListScreen> {
  List<TrainingPackTemplate> _templates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final manifest = jsonDecode(await rootBundle.loadString('AssetManifest.json')) as Map;
      final paths = manifest.keys.where((e) => e.startsWith('assets/training_templates/') && e.endsWith('.json'));
      final list = <TrainingPackTemplate>[];
      for (final p in paths) {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          list.add(TrainingPackTemplate.fromJson(data));
        }
      }
      list.sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() => _templates = list);
    } catch (_) {}
  }

  Future<void> _create(TrainingPackTemplate tpl) async {
    final service = context.read<TrainingPackStorageService>();
    final pack = await service.createPackFromTemplate(tpl);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PackEditorScreen(pack: pack)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шаблоны паков')),
      body: _templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _templates.length,
              itemBuilder: (context, i) {
                final t = _templates[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colorFromHex(t.defaultColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            ElevatedButton(onPressed: () => _create(t), child: const Text('Создать')),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(t.description),
                        if (t.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(spacing: 4, children: [for (final tag in t.tags) Chip(label: Text(tag))]),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
