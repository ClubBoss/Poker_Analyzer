import 'package:flutter/material.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_pack_library_loader_service.dart';
import '../services/training_session_launcher.dart';
import '../services/booster_progress_tracker_service.dart';

class BoosterLibraryScreen extends StatefulWidget {
  const BoosterLibraryScreen({super.key});

  @override
  State<BoosterLibraryScreen> createState() => _BoosterLibraryScreenState();
}

class _BoosterLibraryScreenState extends State<BoosterLibraryScreen> {
  bool _loading = true;
  List<TrainingPackTemplateV2> _packs = [];
  String _tagFilter = '';
  int? _difficultyFilter;
  bool _recommendedOnly = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await TrainingPackLibraryLoaderService.instance.preloadLibrary();
    final all = TrainingPackLibraryLoaderService.instance.loadedTemplates;
    final boosters = [
      for (final p in all)
        if (p.meta['type'] == 'booster') p
    ];
    setState(() {
      _packs = boosters;
      _loading = false;
    });
  }

  List<String> get _tags {
    final set = <String>{};
    for (final p in _packs) {
      final t = p.meta['tag']?.toString();
      if (t != null && t.isNotEmpty) set.add(t);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<TrainingPackTemplateV2> get _filtered {
    return [
      for (final p in _packs)
        if ((_tagFilter.isEmpty || p.meta['tag'] == _tagFilter) &&
            (_difficultyFilter == null ||
                (p.meta['difficulty'] as num?)?.toInt() == _difficultyFilter) &&
            (!_recommendedOnly || p.recommended))
          p
    ];
  }

  String? _difficultyLabel(TrainingPackTemplateV2 p) {
    final d = (p.meta['difficulty'] as num?)?.toInt() ?? 0;
    if (d == 1) return 'Easy';
    if (d == 2) return 'Medium';
    if (d >= 3) return 'Hard';
    return null;
  }

  Future<void> _launch(TrainingPackTemplateV2 pack) async {
    final progress =
        await BoosterProgressTrackerService.instance.getLastIndex(pack.id);
    final completed =
        await BoosterProgressTrackerService.instance.isCompleted(pack.id);
    var start = 0;
    if (!completed &&
        progress != null &&
        progress > 0 &&
        progress < pack.spotCount) {
      final resume = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resume?'),
          content: Text('Continue from spot ${progress + 1}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Restart')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue')),
          ],
        ),
      );
      if (resume == null || resume) {
        start = progress;
      } else {
        await BoosterProgressTrackerService.instance.clearProgress(pack.id);
      }
    }
    await const TrainingSessionLauncher().launch(pack, startIndex: start);
  }

  Widget _buildCard(TrainingPackTemplateV2 p) {
    final tag = p.meta['tag']?.toString();
    final diff = _difficultyLabel(p);
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        BoosterProgressTrackerService.instance.getLastIndex(p.id),
        BoosterProgressTrackerService.instance.isCompleted(p.id),
      ]),
      builder: (context, snapshot) {
        final idx = snapshot.hasData ? snapshot.data![0] as int? : null;
        final completed = snapshot.hasData ? snapshot.data![1] as bool : false;
        return ListTile(
          onTap: () => _launch(p),
          title: Row(
            children: [
              Expanded(child: Text(p.name)),
              if (p.recommended) const Text('🔥')
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.description.isNotEmpty)
                Text(p.description,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              Wrap(
                spacing: 4,
                children: [
                  if (tag != null)
                    Chip(
                        label: Text(tag), visualDensity: VisualDensity.compact),
                  if (diff != null)
                    Chip(
                        label: Text(diff),
                        visualDensity: VisualDensity.compact),
                ],
              )
            ],
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed ? Colors.grey : Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  completed ? '✓' : '${p.spotCount}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if (!completed && idx != null && idx > 0 && idx < p.spotCount)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${idx + 1}/${p.spotCount}',
                      style: const TextStyle(fontSize: 12)),
                )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booster Library')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButton<String>(
                        value: _tagFilter.isEmpty ? '' : _tagFilter,
                        hint: const Text('Tag'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('All')),
                          for (final t in _tags)
                            DropdownMenuItem(value: t, child: Text(t)),
                        ],
                        onChanged: (v) => setState(() => _tagFilter = v ?? ''),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<int>(
                        value: _difficultyFilter ?? 0,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Any')),
                          DropdownMenuItem(value: 1, child: Text('Easy')),
                          DropdownMenuItem(value: 2, child: Text('Medium')),
                          DropdownMenuItem(value: 3, child: Text('Hard')),
                        ],
                        onChanged: (v) => setState(() {
                          _difficultyFilter = v == null || v == 0 ? null : v;
                        }),
                      ),
                      CheckboxListTile(
                        value: _recommendedOnly,
                        onChanged: (v) =>
                            setState(() => _recommendedOnly = v ?? false),
                        title: const Text('Recommended only'),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildCard(_filtered[index]),
                  ),
                ),
              ],
            ),
    );
  }
}
