import 'package:flutter/material.dart';

import '../core/training/controller/built_in_library_controller.dart';
import '../models/v2/training_pack_v2.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _loading = true;
  List<TrainingPackV2> _packs = [];
  List<String> _tags = [];
  List<String> _audiences = [];
  final Set<String> _selectedTags = {};
  final Set<int> _selectedDifficulties = {};
  final Set<String> _selectedAudiences = {};

  String _difficultyIcon(TrainingPackV2 pack) {
    final diff = _difficultyLevel(pack);
    if (diff == 1) return '🟢';
    if (diff == 2) return '🟡';
    if (diff >= 3) return '🔴';
    return '⚪️';
  }

  int _difficultyLevel(TrainingPackV2 pack) {
    final diff = (pack.meta['difficulty'] as num?)?.toInt() ?? pack.difficulty;
    if (diff == 1) return 1;
    if (diff == 2) return 2;
    if (diff >= 3) return 3;
    return 0;
  }

  String _goalText(TrainingPackV2 pack) =>
      (pack.meta['goal'] as String? ?? '').trim();

  @override
  void initState() {
    super.initState();
    BuiltInLibraryController.instance.preload().then((_) {
      if (!mounted) return;
      final list = BuiltInLibraryController.instance.getPacks();
      final counts = <String, int>{};
      final acounts = <String, int>{};
      for (final p in list) {
        for (final t in p.tags) {
          counts[t] = (counts[t] ?? 0) + 1;
        }
        final a = p.meta['audience']?.toString();
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
        if ((_selectedTags.isEmpty ||
                p.tags.toSet().intersection(_selectedTags).isNotEmpty) &&
            (_selectedDifficulties.isEmpty
                ? true
                : (_selectedDifficulties.contains(_difficultyLevel(p)) &&
                    _difficultyLevel(p) != 0)) &&
            (_selectedAudiences.isEmpty
                ? true
                : _selectedAudiences
                    .contains(p.meta['audience']?.toString() ?? '')))
          p
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
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
                if (_tags.isNotEmpty) const SizedBox(height: 8),
                if (_audiences.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final a in _audiences)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(a),
                              selected: _selectedAudiences.contains(a),
                              selectedColor: AppColors.accent,
                              backgroundColor: Colors.grey[700],
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onSelected: (_) {
                                setState(() {
                                  if (_selectedAudiences.contains(a)) {
                                    _selectedAudiences.remove(a);
                                  } else {
                                    _selectedAudiences.add(a);
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_audiences.isNotEmpty) const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final d in [1, 2, 3])
                      FilterChip(
                        label: Text(d == 1
                            ? '🟢 Easy'
                            : d == 2
                                ? '🟡 Medium'
                                : '🔴 Hard'),
                        selected: _selectedDifficulties.contains(d),
                        onSelected: (_) {
                          setState(() {
                            if (_selectedDifficulties.contains(d)) {
                              _selectedDifficulties.remove(d);
                            } else {
                              _selectedDifficulties.add(d);
                            }
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_selectedTags.isNotEmpty ||
                        _selectedDifficulties.isNotEmpty ||
                        _selectedAudiences.isNotEmpty)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedTags.clear();
                          _selectedDifficulties.clear();
                          _selectedAudiences.clear();
                        }),
                        child: const Text('Сбросить'),
                      ),
                    if (_selectedTags.isNotEmpty ||
                        _selectedDifficulties.isNotEmpty ||
                        _selectedAudiences.isNotEmpty)
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
                            _selectedAudiences.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedTags.clear();
                              _selectedDifficulties.clear();
                              _selectedAudiences.clear();
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrainingSessionScreen(pack: pack),
                            ),
                          );
                        },
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
