import 'package:flutter/material.dart';
import 'dart:math';

import '../../models/training_spot.dart';
import '../../theme/app_colors.dart';

class TrainingSpotList extends StatefulWidget {
  final List<TrainingSpot> spots;
  final ValueChanged<int>? onRemove;
  final VoidCallback? onChanged;
  final ReorderCallback? onReorder;
  final bool icmOnly;

  const TrainingSpotList({
    super.key,
    required this.spots,
    this.onRemove,
    this.onChanged,
    this.onReorder,
    this.icmOnly = false,
  });

  @override
  TrainingSpotListState createState() => TrainingSpotListState();
}

class TrainingSpotListState extends State<TrainingSpotList> {
  final TextEditingController _searchController = TextEditingController();
  static const List<String> _availableTags = [
    '3бет пот',
    'Фиш',
    'Рег',
    'ICM',
    'vs агро',
  ];

  static const Map<String, List<String>> _tagPresets = {
    '3бет пот': ['3бет пот'],
    'Фиш': ['Фиш'],
    'Рег': ['Рег'],
    'ICM': ['ICM'],
    'vs агро': ['vs агро'],
  };

  String? _selectedPreset;

  final Set<String> _selectedTags = {};
  final Set<TrainingSpot> _selectedSpots = {};
  bool _tagFiltersExpanded = true;

  Future<void> _editSpot(TrainingSpot spot) async {
    final idController =
        TextEditingController(text: spot.tournamentId ?? '');
    final buyInController =
        TextEditingController(text: spot.buyIn?.toString() ?? '');
    final gameTypeController =
        TextEditingController(text: spot.gameType ?? '');
    final Set<String> localTags = Set<String>.from(spot.tags);

    final updated = await showDialog<TrainingSpot>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text(
                'Редактировать спот',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'ID турнира',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: buyInController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Buy-In',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: gameTypeController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Тип игры',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: [
                        for (final tag in _availableTags)
                          FilterChip(
                            label: Text(tag),
                            selected: localTags.contains(tag),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  localTags.add(tag);
                                } else {
                                  localTags.remove(tag);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      TrainingSpot(
                        playerCards: spot.playerCards,
                        boardCards: spot.boardCards,
                        actions: spot.actions,
                        heroIndex: spot.heroIndex,
                        numberOfPlayers: spot.numberOfPlayers,
                        playerTypes: spot.playerTypes,
                        positions: spot.positions,
                        stacks: spot.stacks,
                        tournamentId: idController.text.trim().isEmpty
                            ? null
                            : idController.text.trim(),
                        buyIn: int.tryParse(buyInController.text.trim()),
                        totalPrizePool: spot.totalPrizePool,
                        numberOfEntrants: spot.numberOfEntrants,
                        gameType: gameTypeController.text.trim().isEmpty
                            ? null
                            : gameTypeController.text.trim(),
                        tags: localTags.toList(),
                      ),
                    );
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated != null) {
      final index = widget.spots.indexOf(spot);
      if (index != -1) {
        setState(() => widget.spots[index] = updated);
        widget.onChanged?.call();
      }
    }
  }

  Future<void> _deleteSpot(TrainingSpot spot) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить спот?'),
        content: const Text(
          'Вы уверены, что хотите удалить этот спот? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (widget.onRemove != null) {
      _selectedSpots.remove(spot);
      widget.onRemove!(widget.spots.indexOf(spot));
      widget.onChanged?.call();
    }
  }

  Future<void> _deleteSelected() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные споты?'),
        content: const Text(
          'Вы уверены, что хотите удалить выбранные споты? Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirm != true || widget.onRemove == null) return;
    final indices = _selectedSpots
        .map((s) => widget.spots.indexOf(s))
        .where((i) => i != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    for (final i in indices) {
      widget.onRemove!(i);
    }
    setState(() {
      _selectedSpots.clear();
    });
    widget.onChanged?.call();
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();
    final filtered = widget.spots.where((spot) {
      final id = spot.tournamentId?.toLowerCase() ?? '';
      final game = spot.gameType?.toLowerCase() ?? '';
      final buyIn = spot.buyIn?.toString() ?? '';
      final matchesQuery = query.isEmpty ||
          id.contains(query) ||
          game.contains(query) ||
          buyIn.contains(query);
      final matchesTags =
          _selectedTags.isEmpty || _selectedTags.every(spot.tags.contains);
      final matchesIcm = !widget.icmOnly || spot.tags.contains('ICM');
      return matchesQuery && matchesTags && matchesIcm;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 8),
        _buildTagFilterSection(filtered),
        const SizedBox(height: 8),
        _buildTagFilterRow(),
        const SizedBox(height: 8),
        if (widget.onRemove != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed:
                  _selectedSpots.isEmpty ? null : _deleteSelected,
              child: const Text('Удалить выбранные'),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: filtered.length <= 1
                ? null
                : () => _shuffleFiltered(filtered),
            child: const Text('Перемешать'),
          ),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          const Text(
            'Нет импортированных спотов',
            style: TextStyle(color: Colors.white54),
          )
        else
          SizedBox(
            height: 150,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final spot = filtered[index];
                return Container(
                  key: ValueKey(spot),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_handle, color: Colors.white70),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _selectedSpots.contains(spot),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedSpots.add(spot);
                            } else {
                              _selectedSpots.remove(spot);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty)
                              Text('ID: ${spot.tournamentId}',
                                  style: const TextStyle(color: Colors.white)),
                            if (spot.buyIn != null)
                              Text('Buy-In: ${spot.buyIn}',
                                  style: const TextStyle(color: Colors.white)),
                            if (spot.gameType != null && spot.gameType!.isNotEmpty)
                              Text('Game: ${spot.gameType}',
                                  style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 4,
                              children: [
                                for (final tag in _availableTags)
                                  FilterChip(
                                    label: Text(tag),
                                    selected: spot.tags.contains(tag),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          if (!spot.tags.contains(tag)) {
                                            spot.tags.add(tag);
                                          }
                                        } else {
                                          spot.tags.remove(tag);
                                        }
                                      });
                                      widget.onChanged?.call();
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: () => _editSpot(spot),
                      ),
                      if (widget.onRemove != null)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSpot(spot),
                        ),
                    ],
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) =>
                  _handleReorder(oldIndex, newIndex, filtered),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Поиск...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: AppColors.cardBackground,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildTagFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final tag in _availableTags)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(tag),
                selected: _selectedTags.contains(tag),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTags.add(tag);
                    } else {
                      _selectedTags.remove(tag);
                    }
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagFilters() {
    return Wrap(
      spacing: 4,
      children: [
        for (final tag in _availableTags)
          FilterChip(
            label: Text(tag),
            selected: _selectedTags.contains(tag),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedTags.add(tag);
                } else {
                  _selectedTags.remove(tag);
                }
              });
            },
          ),
      ],
    );
  }

  Widget _buildTagFilterSection(List<TrainingSpot> filtered) {
    return ExpansionTile(
      title: const Text(
        'Фильтры тегов',
        style: TextStyle(color: Colors.white),
      ),
      initiallyExpanded: _tagFiltersExpanded,
      onExpansionChanged: (v) => setState(() => _tagFiltersExpanded = v),
      iconColor: Colors.white,
      collapsedIconColor: Colors.white,
      collapsedTextColor: Colors.white,
      textColor: Colors.white,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      children: [
        _buildTagFilters(),
        const SizedBox(height: 8),
        _buildPresetDropdown(filtered),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: _clearTagFilters,
            child: const Text('Сбросить теги'),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetDropdown(List<TrainingSpot> filtered) {
    return Row(
      children: [
        const Text('Применить теги ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: _selectedPreset,
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (final entry in _tagPresets.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.key),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            final tags = _tagPresets[value]!;
            setState(() {
              for (final spot in filtered) {
                for (final t in tags) {
                  if (!spot.tags.contains(t)) {
                    spot.tags.add(t);
                  }
                }
              }
              _selectedPreset = null;
            });
            widget.onChanged?.call();
          },
        ),
      ],
    );
  }

  void clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _selectedPreset = null;
    });
  }

  void _clearTagFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedPreset = null;
    });
  }

  void _handleReorder(
    int oldIndex,
    int newIndex,
    List<TrainingSpot> filtered,
  ) {
    if (newIndex > oldIndex) newIndex -= 1;
    final movedSpot = filtered[oldIndex];
    final oldMainIndex = widget.spots.indexOf(movedSpot);
    int newMainIndex;
    if (newIndex >= filtered.length) {
      newMainIndex = widget.spots.length - 1;
    } else {
      final targetSpot = filtered[newIndex];
      newMainIndex = widget.spots.indexOf(targetSpot);
    }
    setState(() {
      final spot = widget.spots.removeAt(oldMainIndex);
      widget.spots.insert(newMainIndex, spot);
    });
    widget.onReorder?.call(oldMainIndex, newMainIndex);
    widget.onChanged?.call();
  }

  void _shuffleFiltered(List<TrainingSpot> filtered) {
    final indices = filtered.map((s) => widget.spots.indexOf(s)).toList();
    final shuffled = List<TrainingSpot>.from(filtered)..shuffle(Random());
    setState(() {
      for (int i = 0; i < indices.length; i++) {
        widget.spots[indices[i]] = shuffled[i];
      }
    });
    widget.onChanged?.call();
  }
}
