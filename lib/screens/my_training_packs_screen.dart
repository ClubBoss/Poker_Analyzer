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
import '../widgets/info_tooltip.dart';
import '../helpers/color_utils.dart';
import '../widgets/color_picker_dialog.dart';

class MyTrainingPacksScreen extends StatefulWidget {
  const MyTrainingPacksScreen({super.key});

  @override
  State<MyTrainingPacksScreen> createState() => _MyTrainingPacksScreenState();
}

class _MyTrainingPacksScreenState extends State<MyTrainingPacksScreen> {
  static const _groupKey = 'group_by_color';
  static const _lastColorKey = 'pack_last_color';
  final Map<String, DateTime?> _dates = {};
  String _sort = 'name';
  int _diffFilter = 0;
  String _colorFilter = 'All';
  bool _groupByColor = false;
  Color _lastColor = Colors.blue;
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
      _colorFilter = prefs.getString('pack_color_filter') ?? 'All';
      _groupByColor = prefs.getBool(_groupKey) ?? false;
      _lastColor = colorFromHex(prefs.getString(_lastColorKey) ?? '#2196F3');
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
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final color = await showColorPickerDialog(
      context,
      initialColor: _lastColor,
    );
    if (color == null) return;
    final hex = colorToHex(color);
    setState(() => _lastColor = color);
    await prefs.setString(_lastColorKey, hex);
    final service = context.read<TrainingPackStorageService>();
    for (final p in _selected) {
      await service.setColorTag(p, hex);
    }
    _clearSelection();
  }

  Future<void> _clearColorTag() async {
    final service = context.read<TrainingPackStorageService>();
    for (final p in _selected) {
      await service.setColorTag(p, '');
    }
    await service.save();
    _clearSelection();
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
    if (_colorFilter != 'All') {
      if (_colorFilter == 'None') {
        packs.retainWhere((p) => p.colorTag.isEmpty);
      } else if (_colorFilter.startsWith('#')) {
        packs.retainWhere((p) => p.colorTag == _colorFilter);
      } else {
        const map = {
          'Red': '#F44336',
          'Blue': '#2196F3',
          'Orange': '#FF9800',
          'Green': '#4CAF50',
          'Purple': '#9C27B0',
          'Grey': '#9E9E9E',
        };
        final hex = map[_colorFilter];
        if (hex != null) packs.retainWhere((p) => p.colorTag == hex);
      }
    }
    final Map<String, List<TrainingPack>> groups = {};
    List<String> categories;
    if (_groupByColor) {
      const hexMap = {
        '#F44336': 'Red',
        '#2196F3': 'Blue',
        '#FF9800': 'Orange',
        '#4CAF50': 'Green',
        '#9C27B0': 'Purple',
        '#9E9E9E': 'Grey',
      };
      packs.sort((a, b) => a.name.compareTo(b.name));
      for (final p in packs) {
        final name = hexMap[p.colorTag] ??
            (p.colorTag.isEmpty ? 'None' : 'Custom');
        groups.putIfAbsent(name, () => []).add(p);
      }
      const order = ['Red', 'Blue', 'Orange', 'Green', 'Purple', 'Grey', 'Custom', 'None'];
      categories = [for (final c in order) if (groups.containsKey(c)) c];
    } else {
      packs.sort(_compare);
      for (final p in packs) {
        groups.putIfAbsent(p.category, () => []).add(p);
      }
      categories = groups.keys.toList()..sort();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Мои паки'), centerTitle: true),
      backgroundColor: AppColors.background,
      bottomNavigationBar: _selectionMode
          ? BottomAppBar(
              child: Row(
                children: [
                  TextButton(
                    onPressed: _setColorTag,
                    child: const Text('🎨 Color Tag'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _clearColorTag,
                    child: const Text('🧹 Clear Color'),
                  ),
                ],
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<String>(
            value: _colorFilter.startsWith('#') ? _colorFilter : _colorFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) async {
              final prefs = _prefs ?? await SharedPreferences.getInstance();
              final value = v ?? 'All';
              if (value == 'Custom') {
                final color = await showColorPickerDialog(
                  context,
                  initialColor: _lastColor,
                );
                if (color == null) return;
                final hex = colorToHex(color);
                setState(() {
                  _colorFilter = hex;
                  _lastColor = color;
                });
                await prefs.setString(_lastColorKey, hex);
                await prefs.setString('pack_color_filter', hex);
                return;
              }
              setState(() => _colorFilter = value);
              if (value == 'All') {
                await prefs.remove('pack_color_filter');
              } else {
                await prefs.setString('pack_color_filter', value);
              }
            },
            items: [
              const DropdownMenuItem(value: 'All', child: Text('Color: All')),
              const DropdownMenuItem(value: 'Red', child: Text('Red')),
              const DropdownMenuItem(value: 'Blue', child: Text('Blue')),
              const DropdownMenuItem(value: 'Orange', child: Text('Orange')),
              const DropdownMenuItem(value: 'Green', child: Text('Green')),
              const DropdownMenuItem(value: 'Purple', child: Text('Purple')),
              const DropdownMenuItem(value: 'Grey', child: Text('Grey')),
              const DropdownMenuItem(value: 'None', child: Text('None')),
              const DropdownMenuItem(value: 'Custom', child: Text('Custom...')),
              if (_colorFilter.startsWith('#'))
                DropdownMenuItem(
                  value: _colorFilter,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: colorFromHex(_colorFilter),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_colorFilter),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Group by Color'),
          value: _groupByColor,
          onChanged: (v) async {
            setState(() => _groupByColor = v);
            final prefs = _prefs ?? await SharedPreferences.getInstance();
            await prefs.setBool(_groupKey, v);
          },
          activeColor: Colors.orange,
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
                      leading: InfoTooltip(
                        message: p.colorTag.isEmpty
                            ? 'No color tag'
                            : 'Color tag ${p.colorTag} (tap to edit)',
                        child: p.colorTag.isEmpty
                            ? const Icon(Icons.circle_outlined, color: Colors.white24)
                            : Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colorFromHex(p.colorTag),
                                  shape: BoxShape.circle,
                                ),
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
