import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../helpers/date_utils.dart';
import 'training_spot_builder_screen.dart';
import 'training_spot_viewer_screen.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() => _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  final TextEditingController _searchController = TextEditingController();
  List<TrainingSpot> _spots = [];
  String _posFilter = 'Все';
  String _tagFilter = 'Все';
  int _sortColumn = 0;
  bool _asc = false;

  @override
  void initState() {
    super.initState();
    _storage = TrainingSpotStorageService(cloud: context.read<CloudSyncService>());
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    setState(() => _spots = loaded);
  }

  Future<void> _save() async => _storage.save(_spots);

  Future<void> _add() async {
    final spot = await Navigator.push<TrainingSpot>(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSpotBuilderScreen()),
    );
    if (spot != null) {
      setState(() => _spots.add(spot));
      await _save();
    }
  }

  Future<void> _edit(int index) async {
    final updated = await Navigator.push<TrainingSpot>(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingSpotBuilderScreen(initialSpot: _spots[index]),
      ),
    );
    if (updated != null) {
      setState(() => _spots[index] = updated);
      await _save();
    }
  }

  Future<void> _delete(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить спот?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _spots.removeAt(index));
      await _save();
    }
  }

  int _compare(TrainingSpot a, TrainingSpot b) {
    int r;
    switch (_sortColumn) {
      case 1:
        final pa = a.heroIndex < a.positions.length ? a.positions[a.heroIndex] : '';
        final pb = b.heroIndex < b.positions.length ? b.positions[b.heroIndex] : '';
        r = pa.compareTo(pb);
        break;
      case 2:
        final sa = a.heroIndex < a.stacks.length ? a.stacks[a.heroIndex] : 0;
        final sb = b.heroIndex < b.stacks.length ? b.stacks[b.heroIndex] : 0;
        r = sa.compareTo(sb);
        break;
      default:
        r = a.createdAt.compareTo(b.createdAt);
    }
    return _asc ? r : -r;
  }

  List<TrainingSpot> _filtered() {
    List<TrainingSpot> list = [..._spots];
    if (_posFilter != 'Все') {
      list = [for (final s in list) if (s.positions.length > s.heroIndex && s.positions[s.heroIndex] == _posFilter) s];
    }
    if (_tagFilter != 'Все') {
      list = [for (final s in list) if (s.tags.contains(_tagFilter)) s];
    }
    final q = _searchController.text.toLowerCase();
    if (q.isNotEmpty) {
      list = [for (final s in list) if (s.tags.any((t) => t.toLowerCase().contains(q))) s];
    }
    list.sort(_compare);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final positions = <String>{for (final s in _spots) if (s.heroIndex < s.positions.length) s.positions[s.heroIndex]};
    final tags = <String>{for (final s in _spots) ...s.tags};
    final visible = _filtered();
    return Scaffold(
      appBar: AppBar(title: const Text('Мои споты'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _posFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  onChanged: (v) => setState(() => _posFilter = v ?? 'Все'),
                  items: ['Все', ...positions].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _tagFilter,
                  dropdownColor: const Color(0xFF2A2B2E),
                  onChanged: (v) => setState(() => _tagFilter = v ?? 'Все'),
                  items: ['Все', ...tags].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _sortColumn,
                  underline: const SizedBox.shrink(),
                  onChanged: (v) => setState(() => _sortColumn = v ?? 0),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('По дате')),
                    DropdownMenuItem(value: 1, child: Text('По позиции')),
                    DropdownMenuItem(value: 2, child: Text('По стеку')),
                  ],
                ),
                IconButton(
                  icon: Icon(_asc ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () => setState(() => _asc = !_asc),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Нет спотов'))
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final spot = visible[index];
                      final pos = spot.heroIndex < spot.positions.length ? spot.positions[spot.heroIndex] : '-';
                      final stack = spot.heroIndex < spot.stacks.length ? spot.stacks[spot.heroIndex] : 0;
                      final bb = (stack / 12.5).round();
                      final i = _spots.indexOf(spot);
                      return Dismissible(
                        key: ValueKey('${spot.createdAt}-$index'),
                        background: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (dir) async {
                          if (dir == DismissDirection.startToEnd) {
                            await _edit(i);
                            return false;
                          } else {
                            await _delete(i);
                            return false;
                          }
                        },
                        child: ListTile(
                          title: Row(
                            children: [
                              SizedBox(width: 80, child: Text(formatDate(spot.createdAt))),
                              SizedBox(width: 80, child: Text(pos)),
                              SizedBox(width: 60, child: Text('$bb BB')),
                              Expanded(child: Text(spot.tags.join(', '))),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrainingSpotViewerScreen(spot: spot)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}
