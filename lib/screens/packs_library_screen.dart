import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/v2/training_pack_template.dart';
import '../services/template_storage_service.dart';
import '../helpers/training_pack_storage.dart';
import 'v2/training_pack_template_editor_screen.dart';
import 'v2/training_session_screen.dart';

class PacksLibraryScreen extends StatefulWidget {
  const PacksLibraryScreen({super.key});

  @override
  State<PacksLibraryScreen> createState() => _PacksLibraryScreenState();
}

class _PacksLibraryScreenState extends State<PacksLibraryScreen> {
  final List<TrainingPackTemplate> _packs = [];
  bool _loaded = false;
  String _query = '';
  String? _difficultyFilter;
  final Set<String> _statusFilters = {};

  List<TrainingPackTemplate> get _filtered => _packs.where((p) {
        final q = _query.toLowerCase();
        final diffOk =
            _difficultyFilter == null || p.difficulty == _difficultyFilter;
        final textOk = p.name.toLowerCase().contains(q) ||
            (p.difficulty?.toLowerCase().contains(q) ?? false);
        var statusOk = true;
        if (_statusFilters.isNotEmpty) {
          final now = DateTime.now();
          final total = p.spots.length;
          final evPct = total == 0 ? 0 : p.evCovered * 100 / total;
          final icmPct = total == 0 ? 0 : p.icmCovered * 100 / total;
          final isNew = now.difference(p.createdAt).inDays < 3;
          final isCompleted = p.evCovered + p.icmCovered >= total * 2;
          final isIncomplete = evPct < 50 || icmPct < 50;
          statusOk = false;
          if (_statusFilters.contains('New') && isNew) statusOk = true;
          if (_statusFilters.contains('Completed') && isCompleted) statusOk = true;
          if (_statusFilters.contains('Incomplete') && isIncomplete) statusOk = true;
        }
        return diffOk && textOk && statusOk;
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
      final json = jsonDecode(await bundle.loadString(p));
      if (json is Map<String, dynamic>) {
        final tpl = TrainingPackTemplate.fromJson(json);
        list.add(tpl);
      }
    }
    list.sort((a, b) {
      final d1 = b.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final d2 = a.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (d1 != d2) return d1.compareTo(d2);
      final covA = a.evCovered + a.icmCovered;
      final covB = b.evCovered + b.icmCovered;
      return covB.compareTo(covA);
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final d in ['Beginner', 'Intermediate', 'Advanced'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(d),
                            selected: _difficultyFilter == d,
                            onSelected: (_) => setState(() =>
                                _difficultyFilter == d
                                    ? _difficultyFilter = null
                                    : _difficultyFilter = d),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ['New', 'Completed', 'Incomplete'])
                        FilterChip(
                          label: Text(s),
                          selected: _statusFilters.contains(s),
                          onSelected: (_) => setState(() {
                            _statusFilters.contains(s)
                                ? _statusFilters.remove(s)
                                : _statusFilters.add(s);
                          }),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty &&
                          (_query.isNotEmpty || _difficultyFilter != null)
                      ? const Center(child: Text('No packs match'))
                      : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final t = _filtered[i];
                        final isNew =
                            DateTime.now().difference(t.createdAt).inDays < 3;
                        final total = t.spots.length;
                final evDone =
                    t.spots.where((s) => s.heroEv != null && !s.dirty).length;
                final icmDone =
                    t.spots.where((s) => s.heroIcmEv != null && !s.dirty).length;
                final solvedAll = t.spots.every(
                    (s) => s.heroEv != null && s.heroIcmEv != null);
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
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          if (t.difficulty != null)
                            Container(
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
                          if (isNew)
                            Chip(
                              label: const Text('NEW'),
                              backgroundColor: Colors.amber,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t.lastTrainedAt != null)
                        Text(
                          'Trained ${timeago.format(t.lastTrainedAt!, locale: 'en_short')}',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white54),
                        ),
                      Text(t.description),
                    ],
                  ),
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
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill),
                        tooltip: solvedAll ? 'All solved' : 'Resume',
                        onPressed: solvedAll
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TrainingSessionScreen(template: t),
                                  ),
                                );
                              },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'import') _import(t);
                          if (v == 'preview') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingPackTemplateEditorScreen(
                                  template: t,
                                  templates: [t],
                                  readOnly: true,
                                ),
                              ),
                            );
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'import', child: Text('Import')),
                          PopupMenuItem(value: 'preview', child: Text('Preview')),
                        ],
                      )
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
