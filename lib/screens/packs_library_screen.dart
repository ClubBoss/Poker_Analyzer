import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/v2/training_pack_template.dart';
import '../services/template_storage_service.dart';
import '../helpers/training_pack_storage.dart';
import 'v2/training_pack_template_editor_screen.dart';

class PacksLibraryScreen extends StatefulWidget {
  const PacksLibraryScreen({super.key});

  @override
  State<PacksLibraryScreen> createState() => _PacksLibraryScreenState();
}

class _PacksLibraryScreenState extends State<PacksLibraryScreen> {
  final List<TrainingPackTemplate> _packs = [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final bundle = DefaultAssetBundle.of(context);
    final manifest =
        jsonDecode(await bundle.loadString('AssetManifest.json')) as Map;
    final paths = manifest.keys
        .where((e) => e.startsWith('assets/packs/') && e.endsWith('.json'));
    final list = <TrainingPackTemplate>[];
    for (final p in paths) {
      final data = jsonDecode(await bundle.loadString(p));
      if (data is Map<String, dynamic>) {
        list.add(TrainingPackTemplate.fromJson(data));
      }
    }
    list.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) setState(() => _packs.addAll(list));
  }

  Future<void> _import(TrainingPackTemplate tpl) async {
    final templates = await TrainingPackStorage.load();
    final newTpl = tpl.copyWith(id: const Uuid().v4(), createdAt: DateTime.now());
    templates.add(newTpl);
    await TrainingPackStorage.save(templates);
    context.read<TemplateStorageService>().addTemplate(newTpl);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingPackTemplateEditorScreen(template: newTpl, templates: templates),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pack Library')),
      body: _packs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _packs.length,
              itemBuilder: (_, i) {
                final t = _packs[i];
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text(t.description),
                  onTap: () => _import(t),
                );
              },
            ),
    );
  }
}
