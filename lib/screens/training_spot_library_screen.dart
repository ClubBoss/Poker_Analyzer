import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';

import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';
import 'training_spot_builder_screen.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() => _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  List<TrainingSpot> _spots = [];
  final Set<TrainingSpot> _selected = {};
  final TextEditingController _searchController = TextEditingController();
  String _positionFilter = 'All';
  String _tagFilter = 'All';

  @override
  void initState() {
    super.initState();
    _storage = context.read<TrainingSpotStorageService>();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _spots = loaded);
  }

  Future<void> _save() async {
    await _storage.save(_spots);
  }

  Future<void> _delete(TrainingSpot spot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete spot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _spots.remove(spot));
    await _save();
  }

  void _toggle(TrainingSpot spot) {
    setState(() {
      if (_selected.contains(spot)) {
        _selected.remove(spot);
      } else {
        _selected.add(spot);
      }
    });
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final spot in _selected) {
        final idx = _spots.indexOf(spot);
        if (idx != -1) {
          final tags = {...spot.tags, tag}..removeWhere((e) => e.isEmpty);
          _spots[idx] = spot.copyWith(tags: tags.toList()..sort());
        }
      }
      _selected.clear();
    });
    await _save();
  }

  Future<void> _removeTag() async {
    final tags = <String>{};
    for (final spot in _selected) {
      tags.addAll(spot.tags);
    }
    String? selected = tags.isNotEmpty ? tags.first : null;
    final tag = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Remove Tag'),
          content: DropdownButton<String>(
            value: selected,
            items: [for (final t in tags) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, selected), child: const Text('OK')),
          ],
        ),
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      for (final spot in _selected) {
        final idx = _spots.indexOf(spot);
        if (idx != -1) {
          final newTags = List<String>.from(spot.tags)..remove(tag);
          _spots[idx] = spot.copyWith(tags: newTags);
        }
      }
      _selected.clear();
    });
    await _save();
  }

  Future<void> _exportCsv() async {
    final rows = <List<String>>[];
    rows.add(['date', 'position', 'stackChips', 'tags']);
    for (final s in _selected) {
      final pos = s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
      final stack = s.stacks.isNotEmpty ? s.stacks[s.heroIndex].toString() : '';
      final date = s.createdAt.toIso8601String();
      rows.add([date, pos, stack, s.tags.join(';')]);
    }
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/spots_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)]);
    if (mounted) setState(() => _selected.clear());
  }

  @override
  Widget build(BuildContext context) {
    final tags = <String>{for (final s in _spots) ...s.tags};
    final positions = <String>{for (final s in _spots) if (s.positions.isNotEmpty) s.positions[s.heroIndex]};
    List<TrainingSpot> visible = [..._spots];
    if (_positionFilter != 'All') {
      visible = [for (final s in visible) if (s.positions.isNotEmpty && s.positions[s.heroIndex] == _positionFilter) s];
    }
    if (_tagFilter != 'All') {
      visible = [for (final s in visible) if (s.tags.contains(_tagFilter)) s];
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      visible = [for (final s in visible) if (s.tags.any((t) => t.toLowerCase().contains(query))) s];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Spots')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Search'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _positionFilter,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) => setState(() => _positionFilter = v ?? 'All'),
                  items: ['All', ...positions]
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _tagFilter,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) => setState(() => _tagFilter = v ?? 'All'),
                  items: ['All', ...tags]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final s = visible[index];
                    final selected = _selected.contains(s);
                    final pos = s.positions.isNotEmpty ? s.positions[s.heroIndex] : '';
                    final stack = s.stacks.isNotEmpty ? s.stacks[s.heroIndex] : 0;
                    return Dismissible(
                      key: ValueKey(s.createdAt),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        await _delete(s);
                        return false;
                      },
                      child: ListTile(
                        leading: Checkbox(
                          value: selected,
                          onChanged: (_) => _toggle(s),
                        ),
                        title: Text('$pos ${stack}bb'),
                        subtitle: s.tags.isNotEmpty ? Text(s.tags.join(', ')) : null,
                        onTap: () => _toggle(s),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: _selected.isNotEmpty ? 56 : 0,
                    child: _selected.isNotEmpty
                        ? Container(
                            color: Colors.black54,
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(onPressed: _addTag, child: const Text('🏷 Add Tag')),
                                ElevatedButton(onPressed: _removeTag, child: const Text('❌ Remove Tag')),
                                ElevatedButton(onPressed: _exportCsv, child: const Text('📄 Export CSV')),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrainingSpotBuilderScreen()),
          );
          if (created == true) _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
