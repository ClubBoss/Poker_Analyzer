import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/training_pack_storage_service.dart';
import '../helpers/date_utils.dart';
import '../models/training_pack.dart';
import '../theme/app_colors.dart';
import 'training_pack_screen.dart';
import '../widgets/difficulty_chip.dart';
import '../helpers/color_utils.dart';

class MyTrainingPacksScreen extends StatefulWidget {
  const MyTrainingPacksScreen({super.key});

  @override
  State<MyTrainingPacksScreen> createState() => _MyTrainingPacksScreenState();
}

class _MyTrainingPacksScreenState extends State<MyTrainingPacksScreen> {
  final Map<String, DateTime?> _dates = {};
  String _sort = 'name';
  int _diffFilter = 0;
  SharedPreferences? _prefs;
  final Set<TrainingPack> _selected = {};

  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadDates();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _diffFilter = prefs.getInt('pack_diff_filter') ?? 0;
    });
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

  void _toggleSelect(TrainingPack pack) {
    setState(() {
      if (_selected.contains(pack)) {
        _selected.remove(pack);
      } else {
        _selected.add(pack);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selected.clear());
  }

  Future<void> _setColorTag() async {
    final color = await _pickColor();
    if (color == null) return;
    final hex = colorToHex(color);
    final service = context.read<TrainingPackStorageService>();
    for (final p in _selected) {
      await service.setColorTag(p, hex);
    }
    _clearSelection();
  }

  Future<Color?> _pickColor() {
    const colors = [
      Colors.red,
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.grey,
    ];
    return showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Color Tag'),
        content: Wrap(
          spacing: 8,
          children: [
            for (final c in colors)
              GestureDetector(
                onTap: () => Navigator.pop(context, c),
                child: CircleAvatar(backgroundColor: c),
              ),
          ],
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs.where((p) => !p.isBuiltIn).toList();
    if (_diffFilter > 0) {
      packs.retainWhere((p) => p.difficulty == _diffFilter);
    }
    packs.sort(_compare);
    final Map<String, List<TrainingPack>> groups = {};
    for (final p in packs) {
      groups.putIfAbsent(p.category, () => []).add(p);
    }
    final categories = groups.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Мои паки'), centerTitle: true),
      backgroundColor: AppColors.background,
      bottomNavigationBar: _selectionMode
          ? BottomAppBar(
              child: TextButton(
                onPressed: _setColorTag,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<int>(
            value: _diffFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) async {
              final value = v ?? 0;
              setState(() => _diffFilter = value);
              final prefs = _prefs ?? await SharedPreferences.getInstance();
              if (value == 0) {
                await prefs.remove('pack_diff_filter');
              } else {
                await prefs.setInt('pack_diff_filter', value);
              }
            },
            items: const [
              DropdownMenuItem(value: 0, child: Text('Difficulty: All')),
              DropdownMenuItem(value: 1, child: Text('Beginner')),
              DropdownMenuItem(value: 2, child: Text('Intermediate')),
              DropdownMenuItem(value: 3, child: Text('Advanced')),
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
                    return ListTile(
                      leading: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorFromHex(p.colorTag),
                          shape: BoxShape.circle,
                        ),
                      ),
                      selected: _selected.contains(p),
                      onLongPress: () => _toggleSelect(p),
                      onTap: () async {
                        if (_selectionMode) {
                          _toggleSelect(p);
                          return;
                        }
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TrainingPackScreen(pack: p)),
                        );
                        if (mounted) await _loadDates();
                      },
                      title: Row(
                        children: [
                          Expanded(child: Text(p.name)),
                          const SizedBox(width: 4),
                          DifficultyChip(p.difficulty),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${p.category} • ${p.spots.isNotEmpty ? '${p.spots.length} spots' : '${p.hands.length} hands'}'),
                          if (p.tags.isNotEmpty) Text(p.tags.join(', ')),
                        ],
                      ),
                      trailing: _selectionMode
                          ? Checkbox(
                              value: _selected.contains(p),
                              onChanged: (_) => _toggleSelect(p),
                            )
                          : Text(date != null ? formatDate(date) : '-'),
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
