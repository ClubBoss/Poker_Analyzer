import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/pack_library_index_loader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import '../core/training/engine/training_type_engine.dart';
import '../services/pack_filter_service.dart';
import '../services/pack_favorite_service.dart';
import '../services/pack_rating_service.dart';
import '../services/training_pack_tags_service.dart';
import '../services/training_pack_audience_service.dart';
import '../services/training_pack_difficulty_service.dart';
import 'pack_library_search_screen.dart';
import 'skill_map_screen.dart';
import 'goal_screen.dart';
import '../models/v2/pack_ux_metadata.dart';

enum _SortOption { newest, rating, difficulty }

class LibraryScreen extends StatefulWidget {
  final Set<String>? initialTags;
  const LibraryScreen({super.key, this.initialTags});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = true;
  List<TrainingPackTemplateV2> _packs = [];
  List<String> _tags = [];
  List<String> _themes = [];
  List<String> _audiences = [];
  List<int> _difficulties = [];
  List<String> _goals = [];
  final Set<String> _selectedTags = {};
  final Set<String> _selectedThemes = {};
  final Set<int> _selectedDifficulties = {};
  final Set<String> _selectedAudiences = {};
  String _selectedGoal = '';
  TrainingPackLevel? _levelFilter;
  final List<TrainingType> _types = TrainingType.values;
  final Set<TrainingType> _selectedTypes = {};
  bool _favoritesOnly = false;
  static const _prefKey = 'hasLoadedLibraryOnce';
  static const _sortPrefKey = 'library_sort_option';

  Map<String, double> _ratings = {};

  _SortOption _sort = _SortOption.newest;

  String _difficultyIconFromLevel(int level) {
    if (level == 1) return '🟢';
    if (level == 2) return '🟡';
    if (level >= 3) return '🔴';
    return '⚪️';
  }

  String _difficultyIcon(TrainingPackTemplateV2 pack) =>
      _difficultyIconFromLevel(_difficultyLevel(pack));

  int _difficultyLevel(TrainingPackTemplateV2 pack) {
    final diff = (pack.meta['difficulty'] as num?)?.toInt();
    if (diff == 1) return 1;
    if (diff == 2) return 2;
    if (diff >= 3) return 3;
    return 0;
  }

  String _levelLabel(TrainingPackLevel l) =>
      l.name[0].toUpperCase() + l.name.substring(1);

  String _goalText(TrainingPackTemplateV2 pack) =>
      pack.goal.isNotEmpty
          ? pack.goal
          : (pack.meta['goal'] as String? ?? '').trim();

  @override
  void initState() {
    super.initState();
    if (widget.initialTags != null) {
      _selectedTags.addAll(widget.initialTags!);
    }
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final sortVal = prefs.getInt(_sortPrefKey);
    if (sortVal != null && sortVal >= 0 && sortVal < _SortOption.values.length) {
      _sort = _SortOption.values[sortVal];
    }
    List<TrainingPackTemplateV2> list;
    if (prefs.getBool(_prefKey) ?? false) {
      list = PackLibraryIndexLoader.instance.library;
      if (list.isEmpty) list = await PackLibraryIndexLoader.instance.load();
    } else {
      list = await PackLibraryIndexLoader.instance.load();
      await prefs.setBool(_prefKey, true);
    }
    final ratingService = PackRatingService.instance;
    final ratingMap = <String, double>{};
    for (final p in list) {
      final r = await ratingService.getAverageRating(p.id);
      if (r != null) ratingMap[p.id] = r;
    }
    if (!mounted) return;
    await TrainingPackTagsService.instance.load(list);
    await TrainingPackAudienceService.instance.load(list);
    await TrainingPackDifficultyService.instance.load(list);
    final goalSet = <String>{};
    final themeMap = <String, String>{};
    for (final p in list) {
      final g = _goalText(p);
      if (g.isNotEmpty) goalSet.add(g);
      final th = p.meta['theme'];
      if (th is String) {
        final t = th.trim();
        if (t.isNotEmpty) themeMap.putIfAbsent(t.toLowerCase(), () => t);
      } else if (th is List) {
        for (final e in th) {
          final t = e.toString().trim();
          if (t.isNotEmpty) {
            themeMap.putIfAbsent(t.toLowerCase(), () => t);
          }
        }
      }
    }
    setState(() {
      _packs = list;
      _tags = TrainingPackTagsService.instance.topTags;
      _themes = themeMap.values.toList()..sort();
      _audiences = TrainingPackAudienceService.instance.topAudiences;
      _difficulties = TrainingPackDifficultyService.instance.topDifficulties;
      _goals = goalSet.toList()..sort();
      _ratings = ratingMap;
      _loading = false;
    });
  }

  Future<void> _setSort(_SortOption value) async {
    if (_sort == value) return;
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sortPrefKey, value.index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final favIds = PackFavoriteService.instance.allFavorites.toSet();
    final baseTemplates = _favoritesOnly
        ? [for (final p in _packs) if (favIds.contains(p.id)) p]
        : _packs;

    final visible = const PackFilterService().filter(
      templates: baseTemplates,
      themes: _selectedThemes.isEmpty ? null : _selectedThemes,
      tags: _selectedTags.isEmpty ? null : _selectedTags,
      types: _selectedTypes.isEmpty ? null : _selectedTypes,
      difficulties:
          _selectedDifficulties.isEmpty ? null : _selectedDifficulties,
      audiences: _selectedAudiences.isEmpty ? null : _selectedAudiences,
      level: _levelFilter,
      goal: _selectedGoal.isEmpty ? null : _selectedGoal,
    );

    DateTime createdAt(TrainingPackTemplateV2 p) {
      final v = p.meta['createdAt'];
      if (v is String) {
        final dt = DateTime.tryParse(v);
        if (dt != null) return dt;
      }
      return p.created;
    }

    visible.sort((a, b) {
      if (_sort == _SortOption.rating) {
        final ra = _ratings[a.id] ?? 0;
        final rb = _ratings[b.id] ?? 0;
        final r = rb.compareTo(ra);
        if (r != 0) return r;
      } else if (_sort == _SortOption.difficulty) {
        final da = _difficultyLevel(a);
        final db = _difficultyLevel(b);
        final r = db.compareTo(da);
        if (r != 0) return r;
      }
      return createdAt(b).compareTo(createdAt(a));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PackLibrarySearchScreen()),
              );
            },
          ),
          IconButton(
            icon: const Text('🎯', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GoalScreen()),
              );
            },
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SkillMapScreen()),
              );
            },
            child: const Text('🧠 Карта навыков'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_goals.isNotEmpty) ...[
                  const Text('🎯 Goal'),
                  DropdownButton<String>(
                    value: _selectedGoal,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('All goals'),
                      ),
                      for (final g in _goals)
                        DropdownMenuItem(value: g, child: Text(g)),
                    ],
                    onChanged: (v) {
                      setState(() => _selectedGoal = v ?? '');
                    },
                  ),
                  const SizedBox(height: 8),
                ],
                if (_themes.isNotEmpty) ...[
                  const Text('🗂 Theme'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final theme in _themes)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(theme),
                              selected: _selectedThemes.contains(theme),
                              selectedColor: AppColors.accent,
                              backgroundColor: Colors.grey[700],
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onSelected: (_) {
                                setState(() {
                                  if (_selectedThemes.contains(theme)) {
                                    _selectedThemes.remove(theme);
                                  } else {
                                    _selectedThemes.add(theme);
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_tags.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tag in _tags)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(tag),
                              selected: _selectedTags.contains(tag),
                              selectedColor: AppColors.accent,
                              backgroundColor: Colors.grey[700],
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onSelected: (_) {
                                setState(() {
                                  if (_selectedTags.contains(tag)) {
                                    _selectedTags.remove(tag);
                                  } else {
                                    _selectedTags.add(tag);
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_types.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final t in _types)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(t.name),
                              selected: _selectedTypes.contains(t),
                              selectedColor: AppColors.accent,
                              backgroundColor: Colors.grey[700],
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onSelected: (_) {
                                setState(() {
                                  if (_selectedTypes.contains(t)) {
                                    _selectedTypes.remove(t);
                                  } else {
                                    _selectedTypes.add(t);
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                if (_tags.isNotEmpty) const SizedBox(height: 8),
                Row(
                  children: [
                    if (_audiences.isNotEmpty)
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedAudiences.isEmpty
                              ? ''
                              : _selectedAudiences.first,
                          hint: const Text('Audience'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(
                              value: '',
                              child: Text('All'),
                            ),
                            for (final a in _audiences)
                              DropdownMenuItem(value: a, child: Text(a)),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _selectedAudiences.clear();
                              if (v != null && v.isNotEmpty) {
                                _selectedAudiences.add(v);
                              }
                            });
                          },
                        ),
                      ),
                    if (_audiences.isNotEmpty) const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedDifficulties.isEmpty
                          ? 0
                          : _selectedDifficulties.first,
                      hint: const Text('Difficulty'),
                      items: [
                        const DropdownMenuItem(value: 0, child: Text('Any')),
                        for (final d in _difficulties)
                          DropdownMenuItem(
                            value: d,
                            child: Text('${_difficultyIconFromLevel(d)} $d'),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedDifficulties.clear();
                          if (v != null && v > 0) {
                            _selectedDifficulties.add(v);
                          }
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<TrainingPackLevel?>(
                      value: _levelFilter,
                      hint: const Text('Level'),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('All')),
                        for (final l in TrainingPackLevel.values)
                          DropdownMenuItem(
                              value: l, child: Text(_levelLabel(l))),
                      ],
                      onChanged: (v) => setState(() => _levelFilter = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _favoritesOnly,
                  title: const Text('⭐️ Только избранные'),
                  activeColor: Colors.amber,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (v) =>
                      setState(() => _favoritesOnly = v ?? false),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DropdownButton<_SortOption>(
                      value: _sort,
                      items: const [
                        DropdownMenuItem(
                            value: _SortOption.newest,
                            child: Text('Сначала новые')),
                        DropdownMenuItem(
                            value: _SortOption.rating,
                            child: Text('По рейтингу')),
                        DropdownMenuItem(
                            value: _SortOption.difficulty,
                            child: Text('По сложности')),
                      ],
                      onChanged: (v) {
                        if (v != null) _setSort(v);
                      },
                    ),
                    const Spacer(),
                    if (_selectedTags.isNotEmpty ||
                        _selectedThemes.isNotEmpty ||
                        _selectedDifficulties.isNotEmpty ||
                        _selectedAudiences.isNotEmpty ||
                        _selectedTypes.isNotEmpty ||
                        _levelFilter != null ||
                        _selectedGoal.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedTags.clear();
                          _selectedThemes.clear();
                          _selectedDifficulties.clear();
                          _selectedAudiences.clear();
                          _selectedTypes.clear();
                          _levelFilter = null;
                          _selectedGoal = '';
                        }),
                        child: const Text('Сбросить'),
                      ),
                    if (_selectedTags.isNotEmpty ||
                        _selectedThemes.isNotEmpty ||
                        _selectedDifficulties.isNotEmpty ||
                        _selectedAudiences.isNotEmpty ||
                        _selectedTypes.isNotEmpty ||
                        _levelFilter != null ||
                        _selectedGoal.isNotEmpty)
                      const SizedBox(width: 12),
                    Text('Найдено: ${visible.length}')
                  ],
                )
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
                        if (_selectedTags.isNotEmpty ||
                            _selectedThemes.isNotEmpty ||
                            _selectedDifficulties.isNotEmpty ||
                            _selectedAudiences.isNotEmpty ||
                            _selectedTypes.isNotEmpty ||
                            _levelFilter != null ||
                            _selectedGoal.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedTags.clear();
                              _selectedThemes.clear();
                              _selectedDifficulties.clear();
                              _selectedAudiences.clear();
                              _selectedTypes.clear();
                              _levelFilter = null;
                              _selectedGoal = '';
                            }),
                            child: const Text('Сбросить'),
                          ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: visible.length + 1,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Встроенные тренировки',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        );
                      }
                      final pack = visible[index - 1];
                      return ListTile(
                        title: Text(pack.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_goalText(pack).isNotEmpty)
                              Text(
                                _goalText(pack),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white60),
                              ),
                            if (pack.tags.isNotEmpty) ...[
                              if (_goalText(pack).isNotEmpty)
                                const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final tag in pack.tags.take(3))
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.white70),
                                      ),
                                    ),
                                  if (pack.tags.length > 3)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '+${pack.tags.length - 3}',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.white70),
                                      ),
                                    ),
                                ],
                              )
                            ]
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_difficultyIcon(pack)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${pack.spotCount}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
