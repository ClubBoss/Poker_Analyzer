import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../services/training_spot_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../helpers/date_utils.dart';
import '../theme/app_colors.dart';
import 'training_spot_builder_screen.dart';
import 'training_spot_analysis_screen.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() => _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  final TextEditingController _searchController = TextEditingController();
  String _position = 'All';
  String _tag = 'All';
  List<TrainingSpot> _spots = [];

  @override
  void initState() {
    super.initState();
    _storage = TrainingSpotStorageService(cloud: context.read<CloudSyncService>());
    _load();
  }

  Future<void> _load() async {
    final loaded = await _storage.load();
    if (mounted) setState(() => _spots = loaded);
  }

  Future<void> _openBuilder({TrainingSpot? spot}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrainingSpotBuilderScreen(spot: spot)),
    );
    await _load();
  }

  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить спот?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
        ],
      ),
    );
    return res == true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posOptions = {'All', ..._spots.map((s) => s.positions[s.heroIndex])};
    final tagOptions = {'All', ..._spots.expand((s) => s.tags)};

    List<TrainingSpot> visible = [..._spots];
    if (_position != 'All') {
      visible = [for (final s in visible) if (s.positions[s.heroIndex] == _position) s];
    }
    if (_tag != 'All') {
      visible = [for (final s in visible) if (s.tags.contains(_tag)) s];
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final s in visible)
          if (s.tags.any((t) => t.toLowerCase().contains(query)) ||
              s.positions.any((p) => p.toLowerCase().contains(query)) ||
              (s.userComment ?? '').toLowerCase().contains(query))
            s
      ];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Мои споты'), centerTitle: true),
      backgroundColor: AppColors.background,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _position,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) => setState(() => _position = v ?? 'All'),
                    items: [for (final p in posOptions) DropdownMenuItem(value: p, child: Text(p))],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _tag,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    onChanged: (v) => setState(() => _tag = v ?? 'All'),
                    items: [for (final t in tagOptions) DropdownMenuItem(value: t, child: Text(t))],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('Нет спотов'))
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final spot = visible[index];
                      return Dismissible(
                        key: ValueKey(spot.createdAt),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            final ok = await _confirmDelete();
                            if (ok) {
                              await _storage.deleteSpot(spot);
                              setState(() => _spots.removeWhere((s) => s.createdAt == spot.createdAt));
                            }
                            return ok;
                          } else {
                            await _openBuilder(spot: spot);
                            return false;
                          }
                        },
                        child: ListTile(
                          title: Text(formatDateTime(spot.createdAt)),
                          subtitle: Text('${spot.positions[spot.heroIndex]} • ${spot.tags.join(', ')}'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TrainingSpotAnalysisScreen(spot: spot)),
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
        onPressed: () => _openBuilder(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
