import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_spot_file_service.dart';
import '../widgets/training_spot_search_bar.dart';
import '../widgets/training_spot_filter_panel.dart';
import '../widgets/training_spot_list_body.dart';

import '../models/training_spot.dart';
import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/training_spot_storage_service.dart';
import 'training_pack_template_editor_screen.dart';
import 'training_spot_builder_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/sync_status_widget.dart';
import '../utils/snackbar_util.dart';

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
  final TrainingSpotFileService _fileService = const TrainingSpotFileService();

  bool _matchesFilters(TrainingSpot spot, Map<String, dynamic> f) {
    final tags = f['tags'];
    if (tags is List && tags.isNotEmpty) {
      if (!tags.every((t) => spot.tags.contains(t))) return false;
    }
    final pos = f['positions'];
    if (pos is List && pos.isNotEmpty) {
      final hero = spot.positions.isNotEmpty ? spot.positions[spot.heroIndex] : '';
      if (!pos.contains(hero)) return false;
    }
    final minDiff = f['minDifficulty'];
    if (minDiff is int && spot.difficulty < minDiff) return false;
    final maxDiff = f['maxDifficulty'];
    if (maxDiff is int && spot.difficulty > maxDiff) return false;
    return true;
  }

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
    await _fileService.shareSpotsCsv(_selected.toList());
    if (mounted) setState(() => _selected.clear());
  }

  Future<void> _createTemplateFromFilter() async {
    final filters = Map<String, dynamic>.from(
        context.read<TrainingSpotStorageService>().activeFilters);
    final initial = TrainingPackTemplateModel(
      id: const Uuid().v4(),
      name: 'Новый шаблон',
      description: '',
      category: '',
      difficulty: 1,
      rating: 0,
      filters: filters,
      isTournament: true,
    );
    final model = await Navigator.push<TrainingPackTemplateModel>(
      context,
      MaterialPageRoute(
          builder: (_) => TrainingPackTemplateEditorScreen(initial: initial)),
    );
    if (model != null && mounted) {
      await context.read<TrainingPackTemplateStorageService>().add(model);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = <String>{for (final s in _spots) ...s.tags};
    final positions = <String>{for (final s in _spots) if (s.positions.isNotEmpty) s.positions[s.heroIndex]};
    List<TrainingSpot> visible = [..._spots];
    final filters = context.watch<TrainingSpotStorageService>().activeFilters;
    if (filters.isNotEmpty) {
      visible = [for (final s in visible) if (_matchesFilters(s, filters)) s];
    }
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
      appBar: AppBar(
        title: const Text('My Spots'),
        actions: [SyncStatusIcon.of(context), 
          if (context.watch<TrainingSpotStorageService>().activeFilters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () {
                final service = context.read<TrainingSpotStorageService>();
                service.activeFilters.clear();
                service.notifyListeners();
                SnackbarUtil.showMessage(context, 'Фильтр сброшен');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          TrainingSpotSearchBar(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
          ),
          TrainingSpotFilterPanel(
            tags: tags,
            positions: positions,
            positionValue: _positionFilter,
            tagValue: _tagFilter,
            onPositionChanged: (v) => setState(() => _positionFilter = v ?? 'All'),
            onTagChanged: (v) => setState(() => _tagFilter = v ?? 'All'),
          ),
          if (filters.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Builder(
                builder: (context) {
                  final templates = context
                      .watch<TrainingPackTemplateStorageService>()
                      .templates;
                  TrainingPackTemplateModel? tpl;
                  for (final t in templates) {
                    if (t.filters.equals(filters)) {
                      tpl = t;
                      break;
                    }
                  }
                  final name = tpl?.name ?? 'пользовательский фильтр';
                  return Text('📦 Активен фильтр: $name');
                },
              ),
            ),
          Expanded(
            child: TrainingSpotListBody(
              spots: visible,
              selected: _selected,
              onToggle: _toggle,
              onDelete: _delete,
              onAddTag: _addTag,
              onRemoveTag: _removeTag,
              onExportCsv: _exportCsv,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'createTplFromFilterFab',
            onPressed: _createTemplateFromFilter,
            label: const Text('Создать шаблон из фильтра'),
            icon: const Icon(Icons.save),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addSpotFab',
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingSpotBuilderScreen()),
              );
              if (created == true) _load();
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
