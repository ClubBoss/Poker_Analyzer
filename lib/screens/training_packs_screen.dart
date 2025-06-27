import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_pack.dart';
import '../models/game_type.dart';
import '../services/training_pack_storage_service.dart';
import '../helpers/color_utils.dart';
import '../widgets/difficulty_chip.dart';
import 'template_library_screen.dart';
import 'training_pack_screen.dart';
import 'training_pack_comparison_screen.dart';
import 'create_pack_screen.dart';

class TrainingPacksScreen extends StatefulWidget {
  const TrainingPacksScreen({super.key});

  @override
  State<TrainingPacksScreen> createState() => _TrainingPacksScreenState();
}

class _TrainingPacksScreenState extends State<TrainingPacksScreen> {
  static const _hideKey = 'hide_completed_packs';
  static const _typeKey = 'pack_game_type_filter';
  static const _diffKey = 'pack_diff_filter';
  static const _colorKey = 'pack_color_filter';

  final TextEditingController _searchController = TextEditingController();

  bool _hideCompleted = false;
  GameType? _typeFilter;
  int _diffFilter = 0;
  String _colorFilter = 'All';
  SharedPreferences? _prefs;

  Future<void> _importPack() async {
    final service = context.read<TrainingPackStorageService>();
    final pack = await service.importPack();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pack == null ? 'Ошибка загрузки пакета' : 'Пакет "${pack.name}" загружен',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _hideCompleted = prefs.getBool(_hideKey) ?? false;
      final t = prefs.getString(_typeKey);
      if (t == 'tournament') _typeFilter = GameType.tournament;
      if (t == 'cash') _typeFilter = GameType.cash;
      _diffFilter = prefs.getInt(_diffKey) ?? 0;
      _colorFilter = prefs.getString(_colorKey) ?? 'All';
    });
  }

  Future<void> _toggleHideCompleted(bool value) async {
    setState(() => _hideCompleted = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_hideKey, value);
  }

  Future<void> _setTypeFilter(GameType? value) async {
    setState(() => _typeFilter = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_typeKey);
    } else {
      await prefs.setString(_typeKey, value.name);
    }
  }

  Future<void> _setDiffFilter(int value) async {
    setState(() => _diffFilter = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == 0) {
      await prefs.remove(_diffKey);
    } else {
      await prefs.setInt(_diffKey, value);
    }
  }

  Future<void> _setColorFilter(String value) async {
    setState(() => _colorFilter = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == 'All') {
      await prefs.remove(_colorKey);
    } else {
      await prefs.setString(_colorKey, value);
    }
  }


  bool _isPackCompleted(TrainingPack pack) {
    final progress = _prefs?.getInt('training_progress_${pack.name}') ?? 0;
    return progress >= pack.hands.length;
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs;

    if (_prefs == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тренировочные споты'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<TrainingPack> visible = _hideCompleted
        ? [for (final p in packs) if (!_isPackCompleted(p)) p]
        : packs;

    if (_typeFilter != null) {
      visible = [for (final p in visible) if (p.gameType == _typeFilter) p];
    }

    if (_diffFilter > 0) {
      visible = [for (final p in visible) if (p.difficulty == _diffFilter) p];
    }

    if (_colorFilter != 'All') {
      if (_colorFilter == 'None') {
        visible = [for (final p in visible) if (p.colorTag.isEmpty) p];
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
        if (hex != null) {
          visible = [for (final p in visible) if (p.colorTag == hex) p];
        }
      }
    }

    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final p in visible)
          if (p.name.toLowerCase().contains(query) ||
              p.description.toLowerCase().contains(query))
            p
      ];
    }

    final bool noRealPacks = packs.isEmpty;

    if (noRealPacks) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Тренировочные споты'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 96, color: Colors.white30),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TemplateLibraryScreen()),
                  );
                },
                child: const Text('Создать из шаблона'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _importPack,
                child: const Text('Импортировать'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final pack = await Navigator.push<TrainingPack>(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePackScreen()),
                  );
                  if (pack != null && context.mounted) {
                    await context.read<TrainingPackStorageService>().addPack(pack);
                  }
                },
                child: const Text('Создать с нуля'),
              ),
            ],
          ),
        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Тренировочные споты'),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Скрыть завершённые'),
            value: _hideCompleted,
            onChanged: _toggleHideCompleted,
            activeColor: Colors.orange,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<GameType?>(
            value: _typeFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setTypeFilter(v),
            items: const [
              DropdownMenuItem(value: null, child: Text('Все')),
              DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
              DropdownMenuItem(value: GameType.cash, child: Text('Cash Game')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DropdownButton<int>(
            value: _diffFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setDiffFilter(v ?? 0),
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
            value: _colorFilter,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setColorFilter(v ?? 'All'),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('Color: All')),
              DropdownMenuItem(value: 'Red', child: Text('Red')),
              DropdownMenuItem(value: 'Blue', child: Text('Blue')),
              DropdownMenuItem(value: 'Orange', child: Text('Orange')),
              DropdownMenuItem(value: 'Green', child: Text('Green')),
              DropdownMenuItem(value: 'Purple', child: Text('Purple')),
              DropdownMenuItem(value: 'Grey', child: Text('Grey')),
              DropdownMenuItem(value: 'None', child: Text('None')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingPackComparisonScreen(),
                      ),
                    );
                  },
                  child: const Text('📊 Сравнить паки'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TemplateLibraryScreen(),
                      ),
                    );
                  },
                  child: const Text('📑 Шаблоны'),
                ),
              ],
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('По текущему фильтру пакетов не найдено'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _hideCompleted = false;
                              _typeFilter = null;
                              _searchController.clear();
                            });
                          },
                          child: const Text('Сбросить фильтры'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final pack = visible[index];
                      final completed = _isPackCompleted(pack);
                      return ListTile(
                        leading: pack.isBuiltIn
                            ? const Text('📦')
                            : (pack.colorTag.isEmpty
                                ? const Icon(Icons.circle_outlined, color: Colors.white24)
                                : Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colorFromHex(pack.colorTag),
                                      shape: BoxShape.circle,
                                    ),
                                  )),
                        title: Row(
                          children: [
                            Expanded(child: Text(pack.name)),
                            const SizedBox(width: 4),
                            DifficultyChip(pack.difficulty),
                          ],
                        ),
                        subtitle: Text(
                          '${pack.spots.isNotEmpty ? '${pack.spots.length} spots' : '${pack.hands.length} hands'} • ${pack.gameType.label}',
                        ),
                        trailing: completed
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingPackScreen(pack: pack),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
