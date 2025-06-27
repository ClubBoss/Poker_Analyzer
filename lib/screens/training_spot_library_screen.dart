import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_spot.dart';
import '../models/training_pack.dart';
import '../models/game_type.dart';
import '../services/training_spot_storage_service.dart';
import '../services/training_pack_storage_service.dart';
import '../services/cloud_sync_service.dart';
import 'create_pack_screen.dart';
import '../widgets/training_spot_preview.dart';

class TrainingSpotLibraryScreen extends StatefulWidget {
  const TrainingSpotLibraryScreen({super.key});

  @override
  State<TrainingSpotLibraryScreen> createState() => _TrainingSpotLibraryScreenState();
}

class _TrainingSpotLibraryScreenState extends State<TrainingSpotLibraryScreen> {
  late TrainingSpotStorageService _storage;
  List<TrainingSpot> _spots = [];
  final Set<TrainingSpot> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storage = TrainingSpotStorageService(cloud: context.read<CloudSyncService>());
    _load();
  }

  Future<void> _load() async {
    final spots = await _storage.load();
    if (mounted) setState(() => _spots = spots);
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

  Future<void> _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить споты?'),
        content: Text('Будет удалено: ${_selected.length}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _spots.removeWhere(_selected.contains));
      await _storage.save(_spots);
      setState(() => _selected.clear());
    }
  }

  Future<void> _createPack() async {
    final pack = await Navigator.push<TrainingPack>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePackScreen(
          initialSpots: _selected.toList(),
          initialPack: TrainingPack(name: '', description: '', hands: const [], gameType: GameType.cash),
        ),
      ),
    );
    if (pack != null && mounted) {
      await context.read<TrainingPackStorageService>().addPack(pack);
      setState(() => _selected.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectionMode) {
          setState(() => _selected.clear());
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectionMode ? 'Выбрано: ${_selected.length}' : 'My Spots'),
          leading: _selectionMode
              ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _selected.clear()))
              : null,
          actions: _selectionMode
              ? [
                  IconButton(icon: const Text('🗑'), onPressed: _deleteSelected),
                  IconButton(icon: const Text('📦'), onPressed: _createPack),
                ]
              : null,
        ),
        body: ListView.builder(
          itemCount: _spots.length,
          itemBuilder: (context, index) {
            final spot = _spots[index];
            return _selectionMode
                ? CheckboxListTile(
                    value: _selected.contains(spot),
                    onChanged: (_) => _toggle(spot),
                    title: Text('Спот ${index + 1}'),
                    subtitle: TrainingSpotPreview(spot: spot),
                    onLongPress: () => _toggle(spot),
                  )
                : ListTile(
                    title: Text('Спот ${index + 1}'),
                    subtitle: TrainingSpotPreview(spot: spot),
                    onLongPress: () {
                      setState(() => _selected.add(spot));
                    },
                  );
          },
        ),
      ),
    );
  }
}
