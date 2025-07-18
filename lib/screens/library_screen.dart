import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/pack_library_index_loader.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../theme/app_colors.dart';
import 'pack_library_search_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = true;
  List<TrainingPackTemplateV2> _packs = [];
  List<String> _tags = [];
  List<String> _audiences = [];
  final Set<String> _selectedTags = {};
  final Set<int> _selectedDifficulties = {};
  final Set<String> _selectedAudiences = {};
  static const _prefKey = 'hasLoadedLibraryOnce';

  String _difficultyIcon(TrainingPackTemplateV2 pack) {
    final diff = _difficultyLevel(pack);
    if (diff == 1) return '🟢';
    if (diff == 2) return '🟡';
    if (diff >= 3) return '🔴';
    return '⚪️';
  }

  int _difficultyLevel(TrainingPackTemplateV2 pack) {
    final diff = (pack.meta['difficulty'] as num?)?.toInt();
    if (diff == 1) return 1;
    if (diff == 2) return 2;
    if (diff >= 3) return 3;
    return 0;
  }

  String _goalText(TrainingPackTemplateV2 pack) =>
      pack.goal.isNotEmpty
          ? pack.goal
          : (pack.meta['goal'] as String? ?? '').trim();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    List<TrainingPackTemplateV2> list;
    if (prefs.getBool(_prefKey) ?? false) {
      list = PackLibraryIndexLoader.instance.library;
      if (list.isEmpty) list = await PackLibraryIndexLoader.instance.load();
    } else {
      list = await PackLibraryIndexLoader.instance.load();
      await prefs.setBool(_prefKey, true);
    }
    if (!mounted) return;
    final counts = <String, int>{};
    final acounts = <String, int>{};
    for (final p in list) {
      for (final t in p.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
      final a = p.audience ?? p.meta['audience']?.toString();
      if (a != null && a.isNotEmpty) {
        acounts[a] = (acounts[a] ?? 0) + 1;
      }
    }
    final tags = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final auds = acounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    setState(() {
      _packs = list;
      _tags = [for (final e in tags.take(20)) e.key];
      _audiences = [for (final e in auds.take(7)) e.key];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final visible = [
      for (final p in _packs)
        if ((_selectedTypes.isEmpty || _selectedTypes.contains(p.trainingType)) &&
            (_selectedTags.isEmpty ||
                p.tags.toSet().intersection(_selectedTags).isNotEmpty) &&
            (_selectedDifficulties.isEmpty
                ? true
                : (_selectedDifficulties.contains(_difficultyLevel(p)) &&
                    _difficultyLevel(p) != 0)) &&
            (_selectedAudiences.isEmpty
                ? true
                : _selectedAudiences
                    .contains((p.audience ?? p.meta['audience']?.toString()) ?? '')))
          p
    ];

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
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (_audiences.isNotEmpty)
                  Row(
                    children: [
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
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _selectedDifficulties.isEmpty
                            ? 0
                            : _selectedDifficulties.first,
                        hint: const Text('Difficulty'),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Any')),
                          DropdownMenuItem(value: 1, child: Text('🟢 1')),
                          DropdownMenuItem(value: 2, child: Text('🟡 2')),
                          DropdownMenuItem(value: 3, child: Text('🔴 3')),
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
                    ],
                  ),
                if (_audiences.isNotEmpty) const SizedBox(height: 8),
                Row(
                  children: [
                    if (_selectedTags.isNotEmpty ||
                        _selectedDifficulties.isNotEmpty ||
                        _selectedAudiences.isNotEmpty ||
                        _selectedTypes.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedTags.clear();
                          _selectedDifficulties.clear();
                          _selectedAudiences.clear();
                          _selectedTypes.clear();
                        }),
                        child: const Text('Сбросить'),
                      ),
                    if (_selectedTags.isNotEmpty ||
                        _selectedDifficulties.isNotEmpty ||
                        _selectedAudiences.isNotEmpty ||
                        _selectedTypes.isNotEmpty)
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
                            _selectedDifficulties.isNotEmpty ||
                            _selectedAudiences.isNotEmpty ||
                            _selectedTypes.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedTags.clear();
                              _selectedDifficulties.clear();
                              _selectedAudiences.clear();
                              _selectedTypes.clear();
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
