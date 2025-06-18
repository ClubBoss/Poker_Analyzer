import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/training_spot.dart';
import '../../theme/app_colors.dart';

enum SortOption {
  buyInAsc,
  buyInDesc,
  gameType,
  tournamentId,
}

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
  static const String _prefsTagsKey = 'training_preset_tags';
  static const String _prefsSearchKey = 'training_preset_search';
  static const String _prefsExpandedKey = 'training_preset_expanded';
  static const String _prefsSortKey = 'training_preset_sort';
  static const String _prefsIcmOnlyKey = 'training_preset_icm_only';
  static const String _prefsOrderKey = 'training_spots_order';
  static const String _prefsListVisibleKey = 'training_spot_list_visible';

  bool _presetsLoaded = false;
  bool _orderRestored = false;
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
  SortOption? _sortOption;
  List<TrainingSpot>? _originalOrder;
  bool _icmOnly = false;
  bool _manualOrder = true;
  bool _listVisible = true;

  List<TrainingSpot> _currentFilteredSpots() {
    final query = _searchController.text.toLowerCase();
    return widget.spots.where((spot) {
      final id = spot.tournamentId?.toLowerCase() ?? '';
      final game = spot.gameType?.toLowerCase() ?? '';
      final buyIn = spot.buyIn?.toString() ?? '';
      final matchesQuery = query.isEmpty ||
          id.contains(query) ||
          game.contains(query) ||
          buyIn.contains(query);
      final matchesTags =
          _selectedTags.isEmpty || _selectedTags.every(spot.tags.contains);
      final matchesIcm = !_icmOnly || spot.tags.contains('ICM');
      return matchesQuery && matchesTags && matchesIcm;
    }).toList();
  }

  String getActiveFilterSummary() {
    final search = _searchController.text.trim();
    final tags = _selectedTags.join(', ');
    var summary = '';
    if (tags.isNotEmpty) summary += tags;
    if (search.isNotEmpty) {
      if (summary.isNotEmpty) summary += ' + ';
      summary += 'поиск: $search';
    }
    return summary;
  }

  Future<void> _loadPresets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _restoreOrderFromPrefs(prefs);
    final List<String> tags = prefs.getStringList(_prefsTagsKey) ?? <String>[];
    final String search = prefs.getString(_prefsSearchKey) ?? '';
    final bool expanded = prefs.getBool(_prefsExpandedKey) ?? true;
    final bool listVisible = prefs.getBool(_prefsListVisibleKey) ?? true;
    final String? sortName = prefs.getString(_prefsSortKey);
    final bool icmOnly = prefs.getBool(_prefsIcmOnlyKey) ?? widget.icmOnly;

    _searchController.text = search;
    _selectedTags
      ..clear()
      ..addAll(tags);
    _tagFiltersExpanded = expanded;
    _listVisible = listVisible;
    _icmOnly = icmOnly;
    if (sortName != null && sortName.isNotEmpty) {
      try {
        _sortOption = SortOption.values.byName(sortName);
      } catch (_) {
        _sortOption = null;
      }
    }
    _manualOrder = _sortOption == null;
    _presetsLoaded = true;
    final filtered = _currentFilteredSpots();
    if (_sortOption != null) {
      _sortFiltered(filtered, _sortOption!);
    } else {
      setState(() {});
    }
    _searchController.addListener(() {
      if (_presetsLoaded) {
        setState(() {});
        _savePresets();
      } else {
        setState(() {});
      }
    });
  }

  Future<void> _savePresets() async {
    if (!_presetsLoaded) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsTagsKey, _selectedTags.toList());
    await prefs.setString(_prefsSearchKey, _searchController.text);
    await prefs.setBool(_prefsExpandedKey, _tagFiltersExpanded);
    await prefs.setBool(_prefsIcmOnlyKey, _icmOnly);
    await prefs.setBool(_prefsListVisibleKey, _listVisible);
    if (_sortOption != null) {
      await prefs.setString(_prefsSortKey, _sortOption!.name);
    } else {
      await prefs.remove(_prefsSortKey);
    }
  }

  Future<void> _saveOrderToPrefs() async {
    if (!_presetsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsOrderKey,
      [for (final s in widget.spots) jsonEncode(s.toJson())],
    );
  }

  Future<void> _restoreOrderFromPrefs(SharedPreferences prefs) async {
    if (_orderRestored || widget.spots.isEmpty) return;
    final stored = prefs.getStringList(_prefsOrderKey);
    if (stored == null || stored.isEmpty) {
      _orderRestored = true;
      return;
    }
    final map = {
      for (final s in widget.spots) jsonEncode(s.toJson()): s
    };
    final reordered = <TrainingSpot>[];
    for (final key in stored) {
      final spot = map.remove(key);
      if (spot != null) reordered.add(spot);
    }
    reordered.addAll(map.values);
    if (reordered.length == widget.spots.length) {
      setState(() {
        widget.spots
          ..clear()
          ..addAll(reordered);
      });
      widget.onChanged?.call();
    }
    _originalOrder = List<TrainingSpot>.from(widget.spots);
    _orderRestored = true;
  }

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

  Future<void> _editTitleAndTags(TrainingSpot spot) async {
    final idController =
        TextEditingController(text: spot.tournamentId ?? '');
    final Set<String> localTags = Set<String>.from(spot.tags);

    final updated = await showDialog<TrainingSpot>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text(
                'Редактировать',
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
                        buyIn: spot.buyIn,
                        totalPrizePool: spot.totalPrizePool,
                        numberOfEntrants: spot.numberOfEntrants,
                        gameType: spot.gameType,
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
      _saveOrderToPrefs();
    }
  }

  Future<void> _deleteSelected() async {
    final count = _selectedSpots.length;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить $count спотов?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Да'),
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
    _saveOrderToPrefs();
  }

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  @override
  void didUpdateWidget(covariant TrainingSpotList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_orderRestored && widget.spots.isNotEmpty && _presetsLoaded) {
      SharedPreferences.getInstance().then(_restoreOrderFromPrefs);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _currentFilteredSpots();

    return DropTarget(
      onDragDone: _handleDrop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
        _buildFilterSummary(),
        _buildIcmSwitch(),
        const SizedBox(height: 8),
        _buildFilterToggleButton(),
        if (_tagFiltersExpanded) ...[
          const SizedBox(height: 8),
          _TagFilterSection(
            filtered: filtered,
            selectedTags: _selectedTags,
            expanded: _tagFiltersExpanded,
            selectedPreset: _selectedPreset,
            onExpanded: (v) {
              setState(() => _tagFiltersExpanded = v);
              _savePresets();
            },
            onTagToggle: (tag, selected) {
              setState(() {
                if (selected) {
                  _selectedTags.add(tag);
                } else {
                  _selectedTags.remove(tag);
                }
              });
              _savePresets();
            },
            onPresetSelected: (value) {
              if (value == null) return;
              final tags = TrainingSpotListState._tagPresets[value]!;
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
            onClearTags: _clearTagFilters,
          ),
        ],
        const SizedBox(height: 8),
        if (widget.onRemove != null) ...[
          _SelectionActions(
            selectedCount: _selectedSpots.length,
            filtered: filtered,
            onSelectAll: _selectAllVisible,
            onClearSelection: _clearSelection,
            onDeleteSelected: _deleteSelected,
          ),
          const SizedBox(height: 8),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Ручной порядок', style: TextStyle(color: Colors.white)),
                  Switch(
                    value: _manualOrder,
                    onChanged: (v) {
                      if (v) {
                        _resetSort();
                      } else {
                        _sortOption ??= SortOption.buyInAsc;
                        _sortFiltered(_currentFilteredSpots(), _sortOption!);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: !_manualOrder || filtered.length <= 1
                    ? null
                    : () => _shuffleFiltered(filtered),
                child: const Text('Перемешать'),
              ),
              const SizedBox(width: 8),
              _SortDropdown(
                sortOption: _sortOption,
                filtered: filtered,
                manualOrder: _manualOrder,
                onChanged: (value, spots) {
                  if (value == null) {
                    _resetSort();
                  } else {
                    _sortFiltered(spots, value);
                  }
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveCurrentOrder,
                child: const Text('Сохранить порядок'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildListToggleButton(),
        const SizedBox(height: 8),
        _buildPackSummary(filtered),
        const SizedBox(height: 8),
        if (_listVisible)
          if (filtered.isEmpty)
            const Text(
              'Нет импортированных спотов',
              style: TextStyle(color: Colors.white54),
            )
          else
            SizedBox(
              height: 150,
              child: _manualOrder
                  ? ReorderableListView.builder(
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
                          widget.onChanged?.call();
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty)
                              GestureDetector(
                                onTap: () => _editTitleAndTags(spot),
                                child: Text(
                                  'ID: ${spot.tournamentId}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            if (spot.buyIn != null)
                              Text('Buy-In: ${spot.buyIn}',
                                  style: const TextStyle(color: Colors.white)),
                            if (spot.gameType != null && spot.gameType!.isNotEmpty)
                              Text('Game: ${spot.gameType}',
                                  style: const TextStyle(color: Colors.white)),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _editTitleAndTags(spot),
                              child: Wrap(
                                spacing: 4,
                                children: [
                                  if (spot.tags.isEmpty)
                                    const Text('Без тегов',
                                        style: TextStyle(color: Colors.white54))
                                  else
                                    for (final tag in spot.tags)
                                      Chip(
                                        label: Text(tag),
                                        backgroundColor: AppColors.cardBackground,
                                      ),
                                ],
                              ),
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
              )
                : ListView.builder(
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
                            const SizedBox(width: 24),
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
                                widget.onChanged?.call();
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (spot.tournamentId != null && spot.tournamentId!.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => _editTitleAndTags(spot),
                                      child: Text(
                                        'ID: ${spot.tournamentId}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  if (spot.buyIn != null)
                                    Text('Buy-In: ${spot.buyIn}',
                                        style: const TextStyle(color: Colors.white)),
                                  if (spot.gameType != null && spot.gameType!.isNotEmpty)
                                    Text('Game: ${spot.gameType}',
                                        style: const TextStyle(color: Colors.white)),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _editTitleAndTags(spot),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        if (spot.tags.isEmpty)
                                          const Text('Без тегов',
                                              style: TextStyle(color: Colors.white54))
                                        else
                                          for (final tag in spot.tags)
                                            Chip(
                                              label: Text(tag),
                                              backgroundColor: AppColors.cardBackground,
                                            ),
                                      ],
                                    ),
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
                  ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed:
                filtered.isEmpty ? null : () => _exportPack(filtered),
            child: const Text('Экспортировать пакет'),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: _importPack,
            child: const Text('Импортировать пакет'),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: clearFilters,
          child: const Text('Сбросить все'),
        ),
      ],
    );
  }

  Widget _buildFilterSummary() {
    final summary = getActiveFilterSummary();
    if (summary.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        summary,
        style: const TextStyle(color: Colors.white60),
      ),
    );
  }

  Widget _buildPackSummary(List<TrainingSpot> filtered) {
    final selected =
        filtered.where((s) => _selectedSpots.contains(s)).length;
    final uniqueTags = <String>{};
    for (final spot in filtered) {
      uniqueTags.addAll(spot.tags);
    }
    return Text(
      'Спотов: ${filtered.length}, Выбрано: $selected, Тегов: ${uniqueTags.length}',
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildIcmSwitch() {
    return SwitchListTile(
      value: _icmOnly,
      onChanged: (v) {
        setState(() => _icmOnly = v);
        _savePresets();
      },
      title: const Text('Только ICM', style: TextStyle(color: Colors.white)),
      activeColor: Colors.orange,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildFilterToggleButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          setState(() => _tagFiltersExpanded = !_tagFiltersExpanded);
          _savePresets();
        },
        child: Text(
          _tagFiltersExpanded ? 'Скрыть фильтры' : 'Показать фильтры',
        ),
      ),
    );
  }

  Widget _buildListToggleButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () {
          setState(() => _listVisible = !_listVisible);
          _savePresets();
        },
        child: Text(
          _listVisible ? 'Скрыть список' : 'Показать список',
        ),
      ),
    );
  }


  void clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _selectedPreset = null;
      _icmOnly = false;
    });
    final bool hadSort = _sortOption != null;
    _resetSort();
    if (!hadSort) widget.onChanged?.call();
    _savePresets();
  }

  void _clearTagFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedPreset = null;
    });
    _savePresets();
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
    _saveOrderToPrefs();
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
    _saveOrderToPrefs();
  }

  void _selectAllVisible(List<TrainingSpot> filtered) {
    setState(() {
      _selectedSpots.addAll(filtered);
    });
    widget.onChanged?.call();
  }

  void _clearSelection() {
    setState(() => _selectedSpots.clear());
    widget.onChanged?.call();
  }

  Future<void> _exportPack(List<TrainingSpot> spots) async {
    if (spots.isEmpty) return;
    final encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final s in spots) s.toJson()]);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_spots_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'training_spots.json');
  }

  Future<void> _importFromFile(String path) async {
    final file = File(path);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is! List) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Неверный формат файла')));
        }
        return;
      }
      final spots = <TrainingSpot>[];
      for (final e in data) {
        if (e is Map) {
          try {
            spots.add(TrainingSpot.fromJson(Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }
      }
      if (spots.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Неверный формат файла')));
        }
        return;
      }
      setState(() => widget.spots.addAll(spots));
      widget.onChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Импортировано спотов: ${spots.length}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка чтения файла')));
      }
    }
  }

  Future<void> _importPack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    await _importFromFile(path);
  }

  Future<void> _handleDrop(DropDoneDetails details) async {
    for (final item in details.files) {
      final path = item.path;
      if (path != null && path.toLowerCase().endsWith('.json')) {
        await _importFromFile(path);
      }
    }
  }

  void _sortFiltered(List<TrainingSpot> filtered, SortOption option) {
    final indices = filtered.map((s) => widget.spots.indexOf(s)).toList();
    final sorted = List<TrainingSpot>.from(filtered);
    _originalOrder ??= List<TrainingSpot>.from(widget.spots);
    switch (option) {
      case SortOption.buyInAsc:
        sorted.sort((a, b) => (a.buyIn ?? 0).compareTo(b.buyIn ?? 0));
        break;
      case SortOption.buyInDesc:
        sorted.sort((a, b) => (b.buyIn ?? 0).compareTo(a.buyIn ?? 0));
        break;
      case SortOption.gameType:
        sorted.sort((a, b) => (a.gameType ?? '').compareTo(b.gameType ?? ''));
        break;
      case SortOption.tournamentId:
        sorted
            .sort((a, b) => (a.tournamentId ?? '').compareTo(b.tournamentId ?? ''));
        break;
    }
    setState(() {
      for (int i = 0; i < indices.length; i++) {
        widget.spots[indices[i]] = sorted[i];
      }
      _sortOption = option;
      _manualOrder = false;
    });
    widget.onChanged?.call();
    _savePresets();
  }

  void _saveCurrentOrder() {
    setState(() {
      _originalOrder = List<TrainingSpot>.from(widget.spots);
      _sortOption = null;
      _manualOrder = true;
    });
    widget.onChanged?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Порядок сохранён')),
    );
    _savePresets();
    _saveOrderToPrefs();
  }

  void _resetSort() {
    if (_sortOption == null) return;
    setState(() {
      if (_originalOrder != null &&
          widget.spots.length == _originalOrder!.length) {
        widget.spots.setAll(0, _originalOrder!);
      }
      _originalOrder = null;
      _sortOption = null;
      _manualOrder = true;
    });
    widget.onChanged?.call();
    _savePresets();
    _saveOrderToPrefs();
  }
}

class _TagFilterSection extends StatelessWidget {
  final List<TrainingSpot> filtered;
  final Set<String> selectedTags;
  final bool expanded;
  final String? selectedPreset;
  final ValueChanged<bool> onExpanded;
  final void Function(String tag, bool selected) onTagToggle;
  final ValueChanged<String?> onPresetSelected;
  final VoidCallback onClearTags;

  const _TagFilterSection({
    required this.filtered,
    required this.selectedTags,
    required this.expanded,
    required this.selectedPreset,
    required this.onExpanded,
    required this.onTagToggle,
    required this.onPresetSelected,
    required this.onClearTags,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpansionTile(
          title: const Text(
            'Фильтры тегов',
            style: TextStyle(color: Colors.white),
          ),
          initiallyExpanded: expanded,
          onExpansionChanged: onExpanded,
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          collapsedTextColor: Colors.white,
          textColor: Colors.white,
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          children: [
            _buildTagFilters(),
            const SizedBox(height: 8),
            _buildPresetDropdown(),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onClearTags,
                child: const Text('Сбросить теги'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTagFilterRow(),
      ],
    );
  }

  Widget _buildTagFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final tag in TrainingSpotListState._availableTags)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(tag),
                selected: selectedTags.contains(tag),
                onSelected: (selected) => onTagToggle(tag, selected),
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
        for (final tag in TrainingSpotListState._availableTags)
          FilterChip(
            label: Text(tag),
            selected: selectedTags.contains(tag),
            onSelected: (selected) => onTagToggle(tag, selected),
          ),
      ],
    );
  }

  Widget _buildPresetDropdown() {
    return Row(
      children: [
        const Text('Применить теги ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<String>(
          value: selectedPreset,
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (final entry in TrainingSpotListState._tagPresets.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(entry.key),
              ),
          ],
          onChanged: onPresetSelected,
        ),
      ],
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final SortOption? sortOption;
  final List<TrainingSpot> filtered;
  final bool manualOrder;
  final void Function(SortOption? value, List<TrainingSpot> spots) onChanged;

  const _SortDropdown({
    required this.sortOption,
    required this.filtered,
    required this.manualOrder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SortOption?>(
      value: sortOption,
      hint: const Text('Сортировать', style: TextStyle(color: Colors.white60)),
      dropdownColor: AppColors.cardBackground,
      style: const TextStyle(color: Colors.white),
      items: const [
        DropdownMenuItem(
          value: null,
          child: Text('Сбросить сортировку'),
        ),
        DropdownMenuItem(
          value: SortOption.buyInAsc,
          child: Text('Buy-In ↑'),
        ),
        DropdownMenuItem(
          value: SortOption.buyInDesc,
          child: Text('Buy-In ↓'),
        ),
        DropdownMenuItem(
          value: SortOption.gameType,
          child: Text('Тип игры'),
        ),
        DropdownMenuItem(
          value: SortOption.tournamentId,
          child: Text('ID турнира'),
        ),
      ],
      onChanged:
          manualOrder ? null : (value) => onChanged(value, filtered),
    );
  }
}

class _SelectionActions extends StatelessWidget {
  final int selectedCount;
  final List<TrainingSpot> filtered;
  final void Function(List<TrainingSpot> spots) onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;

  const _SelectionActions({
    required this.selectedCount,
    required this.filtered,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => onSelectAll(filtered),
            child: const Text('Выделить все'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: selectedCount == 0 ? null : onClearSelection,
            child: const Text('Снять выделение'),
          ),
          const SizedBox(width: 8),
          Stack(
            clipBehavior: Clip.none,
            children: [
              ElevatedButton(
                onPressed: selectedCount == 0 ? null : onDeleteSelected,
                child: const Text('Удалить выбранные'),
              ),
              if (selectedCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$selectedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
