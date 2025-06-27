import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/training_pack_storage_service.dart';
import '../helpers/date_utils.dart';
import '../helpers/color_utils.dart';
import '../models/training_pack.dart';
import '../theme/app_colors.dart';
import '../widgets/color_tag_dialog.dart';
import 'training_pack_screen.dart';

class MyTrainingPacksScreen extends StatefulWidget {
  const MyTrainingPacksScreen({super.key});

  @override
  State<MyTrainingPacksScreen> createState() => _MyTrainingPacksScreenState();
}

class _MyTrainingPacksScreenState extends State<MyTrainingPacksScreen> {
  final Map<String, DateTime?> _dates = {};
  String _sort = 'name';
  final Set<TrainingPack> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    final prefs = await SharedPreferences.getInstance();
    final packs = context.read<TrainingPackStorageService>().packs;
    final map = <String, DateTime?>{};
    for (final p in packs) {
      if (p.isBuiltIn) continue;
      final jsonStr = prefs.getString('results_${p.name}');
      if (jsonStr != null) {
        try {
          final data = jsonDecode(jsonStr);
          if (data is Map && data['history'] is List && data['history'].isNotEmpty) {
            final first = data['history'][0];
            if (first is Map && first['date'] is String) {
              map[p.name] = DateTime.tryParse(first['date']);
            }
          }
        } catch (_) {}
      }
    }
    setState(() => _dates
      ..clear()
      ..addAll(map));
  }

  int _compare(TrainingPack a, TrainingPack b) {
    switch (_sort) {
      case 'date':
        final da = _dates[a.name];
        final db = _dates[b.name];
        if (da == null && db == null) return a.name.compareTo(b.name);
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      default:
        return a.name.compareTo(b.name);
    }
  }

  void _toggleSelect(TrainingPack p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        _selected.add(p);
      }
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  Future<void> _setColorForSelected() async {
    final hex = await showColorTagDialog(context);
    if (hex == null) return;
    final service = context.read<TrainingPackStorageService>();
    for (final p in _selected) {
      final updated = TrainingPack(
        name: p.name,
        description: p.description,
        category: p.category,
        gameType: p.gameType,
        colorTag: hex,
        isBuiltIn: p.isBuiltIn,
        tags: p.tags,
        hands: p.hands,
        spots: p.spots,
        difficulty: p.difficulty,
        history: p.history,
      );
      await service.save(updated);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs.where((p) => !p.isBuiltIn).toList();
    packs.sort(_compare);
    final Map<String, List<TrainingPack>> groups = {};
    for (final p in packs) {
      groups.putIfAbsent(p.category, () => []).add(p);
    }
    final categories = groups.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Мои паки'), centerTitle: true,
          actions: [if (_selected.isNotEmpty) IconButton(icon: const Icon(Icons.close), onPressed: _clearSelection)]),
      backgroundColor: AppColors.background,
      bottomNavigationBar: _selected.isNotEmpty
          ? BottomAppBar(
              child: TextButton(
                onPressed: _setColorForSelected,
                child: const Text('🎨 Color Tag'),
              ),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButton<String>(
              value: _sort,
              underline: const SizedBox.shrink(),
              onChanged: (v) => setState(() => _sort = v ?? 'name'),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('По имени')),
                DropdownMenuItem(value: 'date', child: Text('По дате')),
                DropdownMenuItem(value: 'category', child: Text('По категории')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.fold<int>(0, (n, c) => n + 1 + groups[c]!.length),
              itemBuilder: (context, index) {
                int count = 0;
                for (final cat in categories) {
                  if (index == count) {
                    return Container(
                      color: AppColors.cardBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(cat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    );
                  }
                  count++;
                  final list = groups[cat]!;
                  if (index < count + list.length) {
                    final p = list[index - count];
                    final date = _dates[p.name];
                    final selected = _selected.contains(p);
                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorFromHex(p.colorTag),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p.category} • ${p.hands.length} рук'),
                          if (p.tags.isNotEmpty) Text(p.tags.join(', ')),
                        ],
                      ),
                      trailing: Text(date != null ? formatDate(date) : '-'),
                      selected: selected,
                      onTap: () async {
                        if (_selected.isNotEmpty) {
                          _toggleSelect(p);
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: p)),
                          );
                          if (mounted) await _loadDates();
                        }
                      },
                      onLongPress: () => _toggleSelect(p),
                    );
                  }
                  count += list.length;
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
