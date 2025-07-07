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
                final total = t.spots.length;
                final evDone =
                    t.spots.where((s) => s.heroEv != null && !s.dirty).length;
                final icmDone =
                    t.spots.where((s) => s.heroIcmEv != null && !s.dirty).length;
                double pct(int done) =>
                    total == 0 ? 0 : done * 100 / total;
                Color col(double p) => p >= 80
                    ? Colors.green
                    : p >= 50
                        ? Colors.orange
                        : Colors.red;
                return ListTile(
                  title: Text(t.name),
                  subtitle: Text('${t.description}'),
                  leading: CircleAvatar(child: Text(total.toString())),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatChip(
                        label: '${pct(evDone).round()} % EV',
                        color: col(pct(evDone)),
                      ),
                      const SizedBox(width: 4),
                      _StatChip(
                        label: '${pct(icmDone).round()} % ICM',
                        color: col(pct(icmDone)),
                      ),
                    ],
                  ),
                  onTap: () => _import(t),
                );
              },
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white),
        ),
      );
}
