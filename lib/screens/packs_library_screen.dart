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
  String _query = '';

  List<TrainingPackTemplate> get _filtered =>
      _packs.where((p) {
        final q = _query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            (p.difficulty?.toLowerCase().contains(q) ?? false);
      }).toList();

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
    list.sort((a, b) {
      final aCov = a.evCovered + a.icmCovered;
      final bCov = b.evCovered + b.icmCovered;
      final cmpDate = b.createdAt.compareTo(a.createdAt);
      return cmpDate != 0 ? cmpDate : bCov.compareTo(aCov);
    });
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search packs…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _query = ''),
                            ),
                    ),
                    onChanged: (v) => setState(() => _query = v.trim()),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final t = _filtered[i];
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
                  title: Row(
                    children: [
                      Expanded(child: Text(t.name)),
                      if (t.difficulty != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: t.difficulty == 'Beginner'
                                ? Colors.green
                                : t.difficulty == 'Intermediate'
                                    ? Colors.orange
                                    : t.difficulty == 'Advanced'
                                        ? Colors.red
                                        : Colors.grey,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t.difficulty!,
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Text(t.description),
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
          ),
        ],
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
