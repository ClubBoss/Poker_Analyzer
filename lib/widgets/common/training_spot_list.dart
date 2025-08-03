import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../services/training_pack_tag_analytics_service.dart';

import '../../models/training_spot.dart';
import '../../models/training_pack.dart';
import '../../theme/app_colors.dart';
import '../../screens/training_spot_analysis_screen.dart';
import 'training_spot_list_models.dart';

class TrainingSpotList extends StatefulWidget {
  final List<TrainingSpot> spots;
  final ValueChanged<int>? onRemove;
  final ValueChanged<int>? onEdit;
  final VoidCallback? onChanged;
  final ReorderCallback? onReorder;
  final bool icmOnly;

  const TrainingSpotList({
    super.key,
    required this.spots,
    this.onRemove,
    this.onEdit,
    this.onChanged,
    this.onReorder,
    this.icmOnly = false,
  });

  @override
  TrainingSpotListState createState() => TrainingSpotListState();
}

class TrainingSpotListState extends State<TrainingSpotList>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  static const String _prefsTagsKey = 'training_preset_tags';
  static const String _prefsSearchKey = 'training_preset_search';
  static const String _prefsExpandedKey = 'training_preset_expanded';
  static const String _prefsSortKey = 'training_preset_sort';
  static const String _prefsIcmOnlyKey = 'training_preset_icm_only';
  static const String _prefsRatedOnlyKey = 'training_preset_rated_only';
  static const String _prefsHideCompletedKey = 'training_hide_completed';
  static const String _prefsMistakesKey = 'training_mistakes_only';
  static const String _prefsOrderKey = 'training_spots_order';
  static const String _prefsListVisibleKey = 'training_spot_list_visible';
  static const String _prefsDifficultyKey = 'training_preset_difficulties';
  static const String _prefsRatingsKey = 'training_preset_ratings';
  static const String _prefsRatingSortKey = 'training_preset_rating_sort';
  static const String _prefsSimpleSortField = 'training_simple_sort_field';
  static const String _prefsSimpleSortOrder = 'training_simple_sort_order';
  static const String _prefsCustomPresetsKey =
      'training_custom_tag_presets';
  static const String _prefsQuickPresetKey = 'training_quick_preset';
  static const String _prefsSearchHistoryKey = 'training_search_history';
  static const String _prefsListSortKey = 'training_spot_list_sort';
  static const String _prefsQuickSortKey = 'training_quick_sort_option';

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

  static const Map<String, String> _quickFilterPresets = {
    'ICM': 'ICM',
    'Push/Fold': 'Push/Fold',
    'Postflop': 'Postflop',
    '3-bet': '3-bet',
    'Bubble': 'Bubble',
  };

  Map<String, List<String>> _customTagPresets = {};

  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];

  String? _selectedPreset;
  String? _activeQuickPreset;
  Set<String>? _prevQuickTags;

  final Set<String> _selectedTags = {};
  final Set<TrainingSpot> _selectedSpots = {};
  bool _tagFiltersExpanded = true;
  SortOption? _sortOption;
  List<TrainingSpot>? _originalOrder;
  bool _icmOnly = false;
  bool _ratedOnly = false;
  bool _hideCompleted = false;
  bool _manualOrder = true;
  bool _listVisible = true;
  final Set<int> _difficultyFilters = {};
  final Set<int> _ratingFilters = {};
  final Set<String> _mistakeIds = {};
  RatingSortOrder? _ratingSort;
  SimpleSortField? _simpleSortField;
  SimpleSortOrder _simpleSortOrder = SimpleSortOrder.ascending;
  ListSortOption? _listSort;
  QuickSortOption? _quickSort;
  bool _mistakesOnly = false;

  FilterState? _lastFilterState;

  void _restoreFilterState(FilterState state) {
    setState(() {
      _searchController.text = state.searchText;
      _selectedTags
        ..clear()
        ..addAll(state.selectedTags);
      _activeQuickPreset = null;
      _prevQuickTags = null;
      _difficultyFilters
        ..clear()
        ..addAll(state.difficultyFilters);
      _ratingFilters
        ..clear()
        ..addAll(state.ratingFilters);
      _icmOnly = state.icmOnly;
      _ratedOnly = state.ratedOnly;
    });
    _savePresets();
  }

  Future<MapEntry<String, List<String>>?> _editTagPreset(
      {String? initialName, List<String>? initialTags}) async {
    final controller = TextEditingController(text: initialName ?? '');
    final local = <String>{...(initialTags ?? [])};
    final suggestions = <String>{
      ..._availableTags,
      for (final list in _tagPresets.values) ...list,
      for (final list in _customTagPresets.values) ...list,
      for (final s in widget.spots) ...s.tags,
    }..removeWhere((e) => e.isEmpty);
    final result = await showDialog<MapEntry<String, List<String>>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Text(
            initialName == null ? 'Новый пресет' : 'Редактировать пресет',
            style: const TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Название',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final tag in suggestions)
                            CheckboxListTile(
                              value: local.contains(tag),
                              title: Text(tag,
                                  style: const TextStyle(color: Colors.white)),
                              onChanged: (v) {
                                setStateDialog(() {
                                  if (v ?? false) {
                                    local.add(tag);
                                  } else {
                                    local.remove(tag);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                  context, MapEntry(controller.text.trim(), local.toList())),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (result == null || result.key.isEmpty) return null;
    return result;
  }

  Future<void> _manageTagPresets() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final staticEntries = _tagPresets.entries.toList();
            final customEntries = _customTagPresets.entries.toList();
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text('Пресеты тегов',
                  style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 300,
                height: 400,
                child: Column(
                  children: [
                    Expanded(
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) {
                          final staticCount = staticEntries.length;
                          if (oldIndex < staticCount || newIndex <= staticCount) {
                            return;
                          }
                          final localOld = oldIndex - staticCount;
                          var localNew = newIndex - staticCount;
                          if (localNew > localOld) localNew--;
                          final moved = customEntries.removeAt(localOld);
                          customEntries.insert(localNew, moved);
                          setStateDialog(() {
                            _customTagPresets = {
                              for (final e in customEntries) e.key: e.value,
                            };
                          });
                        },
                        children: [
                          for (final entry in staticEntries)
                            ListTile(
                              key: ValueKey('s_${entry.key}'),
                              title: Text(entry.key,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(entry.value.join(', '),
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              trailing: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete, color: Colors.grey),
                                ],
                              ),
                            ),
                          for (final entry in customEntries)
                            ListTile(
                              key: ValueKey(entry.key),
                              title: Text(entry.key,
                                  style: const TextStyle(color: Colors.white)),
                              subtitle: Text(entry.value.join(', '),
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.white),
                                    onPressed: () async {
                                      final result = await _editTagPreset(
                                          initialName: entry.key,
                                          initialTags: entry.value);
                                      if (result != null) {
                                        setStateDialog(() {
                                          _customTagPresets.remove(entry.key);
                                          _customTagPresets[result.key] =
                                              result.value;
                                        });
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(
                                              'Удалить пресет "${entry.key}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Отмена'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Удалить'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        setStateDialog(() {
                                          _customTagPresets.remove(entry.key);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _editTagPreset();
                          if (result != null &&
                              !_customTagPresets.containsKey(result.key)) {
                            setStateDialog(() {
                              _customTagPresets[result.key] = result.value;
                            });
                          }
                        },
                        child: const Text('Создать новый пресет'),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Закрыть'),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
    _savePresets();
  }

  List<TrainingSpot> _currentFilteredSpots() {
    final query = _searchController.text.toLowerCase();
    return widget.spots.where((spot) {
      final id = spot.tournamentId?.toLowerCase() ?? '';
      bool matchesQuery = query.isEmpty;
      if (!matchesQuery) {
        final tagMatch = spot.tags.any((t) => t.toLowerCase().contains(query));
        final comment = spot.userComment?.toLowerCase() ?? '';
        final history = spot.actionHistory?.toLowerCase() ?? '';
        final actions = spot.actions
            .map((a) =>
                '${a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action} ${a.amount ?? ''} ${a.street} ${a.playerIndex}')
            .join(' ')
            .toLowerCase();
        matchesQuery =
            id.contains(query) ||
            tagMatch ||
            comment.contains(query) ||
            history.contains(query) ||
            actions.contains(query);
      }
      final matchesTags =
          _selectedTags.isEmpty || _selectedTags.every(spot.tags.contains);
      final matchesIcm = !_icmOnly || spot.tags.contains('ICM');
      final matchesDifficulty =
          _difficultyFilters.isEmpty ||
              _difficultyFilters.contains(spot.difficulty);
      final matchesRating =
          _ratingFilters.isEmpty || _ratingFilters.contains(spot.rating);
      final matchesRated = !_ratedOnly || spot.userAction != null;
      final matchesCompleted =
          !_hideCompleted || spot.userAction == null || spot.correct == null;
      final matchesMistake = !_mistakesOnly ||
          (spot.tournamentId != null &&
              _mistakeIds.contains(spot.tournamentId!));
      return
          matchesQuery &&
          matchesTags &&
          matchesIcm &&
          matchesDifficulty &&
          matchesRating &&
          matchesRated &&
          matchesCompleted &&
          matchesMistake;
    }).toList();
  }

  TextSpan _highlightSpan(String text) {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      return TextSpan(text: text, style: const TextStyle(color: Colors.white));
    }
    final lcText = text.toLowerCase();
    final lcQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int index;
    while ((index = lcText.indexOf(lcQuery, start)) != -1) {
      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index),
            style: const TextStyle(color: Colors.white)));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(color: Colors.orange)));
      start = index + query.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(color: Colors.white)));
    }
    return TextSpan(children: spans);
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
    if (_difficultyFilters.isNotEmpty) {
      if (summary.isNotEmpty) summary += ' + ';
      summary += 'сложность: ${_difficultyFilters.join(', ')}';
    }
    if (_ratingFilters.isNotEmpty) {
      if (summary.isNotEmpty) summary += ' + ';
      summary += 'рейтинг: ${_ratingFilters.join(', ')}';
    }
    if (_ratedOnly) {
      if (summary.isNotEmpty) summary += ' + ';
      summary += 'только с оценкой';
    }
    if (_mistakesOnly) {
      if (summary.isNotEmpty) summary += ' + ';
      summary += 'ошибки';
    }
    return summary;
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _selectedTags.isNotEmpty ||
        _difficultyFilters.isNotEmpty ||
        _ratingFilters.isNotEmpty ||
        _icmOnly ||
        _ratedOnly ||
        _mistakesOnly;
  }

  Future<void> _loadPresets() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await _restoreOrderFromPrefs(prefs);
    final List<String> tags = prefs.getStringList(_prefsTagsKey) ?? <String>[];
    final String search = prefs.getString(_prefsSearchKey) ?? '';
    final bool expanded = prefs.getBool(_prefsExpandedKey) ?? true;
    final bool listVisible = prefs.getBool(_prefsListVisibleKey) ?? true;
    final String? sortName = prefs.getString(_prefsSortKey);
    final String? ratingSortName = prefs.getString(_prefsRatingSortKey);
    final String? simpleFieldName = prefs.getString(_prefsSimpleSortField);
    final String? simpleOrderName = prefs.getString(_prefsSimpleSortOrder);
    final String? listSortName = prefs.getString(_prefsListSortKey);
    final String? quickSortName = prefs.getString(_prefsQuickSortKey);
    final bool icmOnly = prefs.getBool(_prefsIcmOnlyKey) ?? widget.icmOnly;
    final bool ratedOnly = prefs.getBool(_prefsRatedOnlyKey) ?? false;
    final bool hideCompleted = prefs.getBool(_prefsHideCompletedKey) ?? false;
    final bool mistakesOnly = prefs.getBool(_prefsMistakesKey) ?? false;
    final List<String>? diffs = prefs.getStringList(_prefsDifficultyKey);
    final List<String>? ratings = prefs.getStringList(_prefsRatingsKey);
    final String? customJson = prefs.getString(_prefsCustomPresetsKey);
    final String? quickPreset = prefs.getString(_prefsQuickPresetKey);
    _searchHistory =
        prefs.getStringList(_prefsSearchHistoryKey) ?? <String>[];
    if (customJson != null && customJson.isNotEmpty) {
      final Map<String, dynamic> decoded = jsonDecode(customJson);
      _customTagPresets = {
        for (final e in decoded.entries) e.key: List<String>.from(e.value as List)
      };
    }

    _searchController.text = search;
    _selectedTags
      ..clear()
      ..addAll(tags);
    _activeQuickPreset = quickPreset;
    if (_activeQuickPreset != null) {
      _prevQuickTags = Set<String>.from(_selectedTags);
      final tag = _quickFilterPresets[_activeQuickPreset!];
      if (tag != null) {
        _selectedTags
          ..clear()
          ..add(tag);
      } else {
        _activeQuickPreset = null;
      }
    }
    _tagFiltersExpanded = expanded;
    _listVisible = listVisible;
    _icmOnly = icmOnly;
    _ratedOnly = ratedOnly;
    _hideCompleted = hideCompleted;
    _mistakesOnly = mistakesOnly;
    _difficultyFilters
      ..clear()
      ..addAll(diffs == null
          ? []
          : diffs
              .map(int.tryParse)
              .whereType<int>()
              .where((d) => d >= 1 && d <= 5));
    _ratingFilters
      ..clear()
      ..addAll(ratings == null
          ? []
          : ratings
              .map(int.tryParse)
              .whereType<int>()
              .where((r) => r >= 1 && r <= 5));
    if (sortName != null && sortName.isNotEmpty) {
      try {
        _sortOption = SortOption.values.byName(sortName);
      } catch (_) {
        _sortOption = null;
      }
    }
    if (ratingSortName != null && ratingSortName.isNotEmpty) {
      try {
        _ratingSort = RatingSortOrder.values.byName(ratingSortName);
      } catch (_) {
        _ratingSort = null;
      }
    }
    if (simpleFieldName != null && simpleFieldName.isNotEmpty) {
      try {
        _simpleSortField = SimpleSortField.values.byName(simpleFieldName);
      } catch (_) {
        _simpleSortField = null;
      }
    }
    if (simpleOrderName != null && simpleOrderName.isNotEmpty) {
      try {
        _simpleSortOrder = SimpleSortOrder.values.byName(simpleOrderName);
      } catch (_) {
        _simpleSortOrder = SimpleSortOrder.ascending;
      }
    }
    if (listSortName != null && listSortName.isNotEmpty) {
      try {
        _listSort = ListSortOption.values.byName(listSortName);
      } catch (_) {
        _listSort = null;
      }
    }
    if (quickSortName != null && quickSortName.isNotEmpty) {
      try {
        _quickSort = QuickSortOption.values.byName(quickSortName);
      } catch (_) {
        _quickSort = null;
      }
    }
    _manualOrder = _sortOption == null &&
        _ratingSort == null &&
        _simpleSortField == null &&
        _listSort == null &&
        _quickSort == null;
    _presetsLoaded = true;
    final filtered = _currentFilteredSpots();
    if (_sortOption != null) {
      _sortFiltered(filtered, _sortOption!);
    } else if (_ratingSort != null) {
      _sortByRating(filtered, _ratingSort!);
    } else if (_simpleSortField != null) {
      _applySimpleSort(filtered);
    } else if (_listSort != null) {
      _applyListSort(filtered);
    } else if (_quickSort != null) {
      _applyQuickSort(filtered);
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
    await prefs.setBool(_prefsRatedOnlyKey, _ratedOnly);
    await prefs.setBool(_prefsHideCompletedKey, _hideCompleted);
    await prefs.setBool(_prefsMistakesKey, _mistakesOnly);
    await prefs.setBool(_prefsListVisibleKey, _listVisible);
    if (_difficultyFilters.isNotEmpty) {
      await prefs.setStringList(_prefsDifficultyKey,
          _difficultyFilters.map((e) => e.toString()).toList());
    } else {
      await prefs.remove(_prefsDifficultyKey);
    }
    if (_ratingFilters.isNotEmpty) {
      await prefs.setStringList(_prefsRatingsKey,
          _ratingFilters.map((e) => e.toString()).toList());
    } else {
      await prefs.remove(_prefsRatingsKey);
    }
    if (_ratingSort != null) {
      await prefs.setString(_prefsRatingSortKey, _ratingSort!.name);
    } else {
      await prefs.remove(_prefsRatingSortKey);
    }
    if (_simpleSortField != null) {
      await prefs.setString(_prefsSimpleSortField, _simpleSortField!.name);
    } else {
      await prefs.remove(_prefsSimpleSortField);
    }
    await prefs.setString(_prefsSimpleSortOrder, _simpleSortOrder.name);
    if (_listSort != null) {
      await prefs.setString(_prefsListSortKey, _listSort!.name);
    } else {
      await prefs.remove(_prefsListSortKey);
    }
    if (_quickSort != null) {
      await prefs.setString(_prefsQuickSortKey, _quickSort!.name);
    } else {
      await prefs.remove(_prefsQuickSortKey);
    }
    if (_sortOption != null) {
      await prefs.setString(_prefsSortKey, _sortOption!.name);
    } else {
      await prefs.remove(_prefsSortKey);
    }
    if (_activeQuickPreset != null) {
      await prefs.setString(_prefsQuickPresetKey, _activeQuickPreset!);
    } else {
      await prefs.remove(_prefsQuickPresetKey);
    }
    await prefs.setString(
        _prefsCustomPresetsKey, jsonEncode(_customTagPresets));
  }

  Future<void> _saveOrderToPrefs() async {
    if (!_presetsLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsOrderKey,
      [for (final s in widget.spots) jsonEncode(s.toJson())],
    );
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsSearchHistoryKey, _searchHistory);
  }

  Future<void> _addToSearchHistory(String query) async {
    query = query.trim();
    if (query.isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 5) {
      _searchHistory = _searchHistory.sublist(0, 5);
    }
    await _saveSearchHistory();
  }

  Future<void> _clearSearchHistory() async {
    _searchHistory.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsSearchHistoryKey);
  }

  Future<void> _loadMistakeIds() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/training_packs.json');
    if (!await file.exists()) return;
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is List) {
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            final pack = TrainingPack.fromJson(Map<String, dynamic>.from(item));
            for (final r in pack.history) {
              for (final t in r.tasks) {
                if (!t.correct) _mistakeIds.add(t.question);
              }
            }
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _showSearchHistoryDropdown(BuildContext context) async {
    if (_searchHistory.isEmpty) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(
      context: context,
      color: AppColors.cardBackground,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        0,
      ),
      items: [
        for (final q in _searchHistory)
          PopupMenuItem<String>(value: q, child: Text(q)),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__clear__',
          child: Text('Очистить историю'),
        ),
      ],
    );
    if (selected == null) return;
    if (selected == '__clear__') {
      await _clearSearchHistory();
    } else {
      _searchController.text = selected;
      await _addToSearchHistory(selected);
    }
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
                        equities: spot.equities,
                        tournamentId: idController.text.trim().isEmpty
                            ? null
                            : idController.text.trim(),
                        buyIn: int.tryParse(buyInController.text.trim()),
                        totalPrizePool: spot.totalPrizePool,
                        numberOfEntrants: spot.numberOfEntrants,
                        gameType: gameTypeController.text.trim().isEmpty
                            ? null
                            : gameTypeController.text.trim(),
                        difficulty: spot.difficulty,
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
    final titleController =
        TextEditingController(text: spot.tournamentId ?? '');
    final tagsController =
        TextEditingController(text: spot.tags.join(', '));

    final updated = await showDialog<TrainingSpot>(
      context: context,
      builder: (context) {
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
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Теги (через запятую)',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                  ),
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
                final tags = tagsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
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
                    equities: spot.equities,
                    tournamentId: titleController.text.trim().isEmpty
                        ? null
                        : titleController.text.trim(),
                    buyIn: spot.buyIn,
                    totalPrizePool: spot.totalPrizePool,
                    numberOfEntrants: spot.numberOfEntrants,
                    gameType: spot.gameType,
                    difficulty: spot.difficulty,
                    tags: tags,
                  ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
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

  void _duplicateSpot(TrainingSpot spot) {
    final index = widget.spots.indexOf(spot);
    if (index == -1) return;
    setState(() {
      final copy = spot.copy();
      widget.spots.insert(index + 1, copy);
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
  }

  Future<void> _editComment(TrainingSpot spot) async {
    final controller = TextEditingController(text: spot.userComment ?? '');

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Комментарий',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Комментарий',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final index = widget.spots.indexOf(spot);
      if (index != -1) {
        setState(() {
          widget.spots[index] =
              spot.copyWith(userComment: result.isEmpty ? null : result);
        });
        widget.onChanged?.call();
        _saveOrderToPrefs();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Комментарий обновлен')));
      }
    }
  }

  Future<void> _editActionHistory(TrainingSpot spot) async {
    final controller = TextEditingController(text: spot.actionHistory ?? '');

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'История действий',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: TextField(
                controller: controller,
                maxLines: null,
                minLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'История действий',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final index = widget.spots.indexOf(spot);
      if (index != -1) {
        setState(() {
          widget.spots[index] =
              spot.copyWith(actionHistory: result.isEmpty ? null : result);
        });
        widget.onChanged?.call();
        _saveOrderToPrefs();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('История действий обновлена')));
      }
    }
  }

  Future<void> _editTagsForSpot(TrainingSpot spot) async {
    final Set<String> localTags = Set<String>.from(spot.tags);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              title: const Text(
                'Редактировать теги',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final tag in _availableTags)
                      CheckboxListTile(
                        value: localTags.contains(tag),
                        title:
                            Text(tag, style: const TextStyle(color: Colors.white)),
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v ?? false) {
                              localTags.add(tag);
                            } else {
                              localTags.remove(tag);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Отмена'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final index = widget.spots.indexOf(spot);
    if (index == -1) return;
    setState(() {
      final sorted = localTags.toList()..sort();
      widget.spots[index] = spot.copyWith(tags: sorted);
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Теги обновлены')));
  }

  Future<void> _quickAddTagsForSpot(TrainingSpot spot) async {
    final suggestions = <String>{
      ...TrainingSpotListState._availableTags,
      for (final list in TrainingSpotListState._tagPresets.values) ...list,
      for (final list in _customTagPresets.values) ...list,
      for (final s in widget.spots) ...s.tags,
    }..removeWhere((e) => e.isEmpty);

    final addTags = <String>{};
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Добавить тег',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Тег',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    onSubmitted: (value) {
                      final tag = value.trim();
                      if (tag.isEmpty) return;
                      setStateDialog(() {
                        addTags.add(tag);
                      });
                      controller.clear();
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final tag in (suggestions.toList()..sort()))
                        InputChip(
                          label: Text(tag),
                          onPressed: () {
                            setStateDialog(() {
                              addTags.add(tag);
                            });
                          },
                        ),
                      for (final tag in addTags.toList()..sort())
                        Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setStateDialog(() {
                              addTags.remove(tag);
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Добавить'),
              ),
            ],
          );
        });
      },
    );

    if (confirmed != true || addTags.isEmpty) return;

    final index = widget.spots.indexOf(spot);
    if (index == -1) return;
    setState(() {
      final tags = <String>{...spot.tags}..addAll(addTags);
      final sorted = tags.toList()..sort();
      widget.spots[index] = spot.copyWith(tags: sorted);
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Добавлено ${addTags.length} тегов')),
    );
  }

  void _updateDifficulty(TrainingSpot spot, int value) {
    final index = widget.spots.indexOf(spot);
    if (index == -1) return;
    setState(() {
      widget.spots[index] = spot.copyWith(difficulty: value);
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Сложность обновлена')));
  }

  void _updateRating(TrainingSpot spot, int value) {
    final index = widget.spots.indexOf(spot);
    if (index == -1) return;
    setState(() {
      widget.spots[index] = spot.copyWith(rating: value);
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Рейтинг обновлен')));
  }

  void _applyDifficultyToFiltered(int value) {
    final filtered = _currentFilteredSpots();
    if (filtered.isEmpty) return;
    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          widget.spots[index] = spot.copyWith(difficulty: value);
        }
      }
    });
    widget.onChanged?.call();
  }

  void _applyRatingToFiltered(int value) {
    final filtered = _currentFilteredSpots();
    if (filtered.isEmpty) return;
    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          widget.spots[index] = spot.copyWith(rating: value);
        }
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
  }

  void _applyActiveFiltersToFiltered(List<TrainingSpot> filtered) {
    if (filtered.isEmpty) return;
    final diff = _difficultyFilters.length == 1 ? _difficultyFilters.first : null;
    final rate = _ratingFilters.length == 1 ? _ratingFilters.first : null;
    if (diff == null && rate == null) return;
    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          var updated = spot;
          if (diff != null) {
            updated = updated.copyWith(difficulty: diff);
          }
          if (rate != null) {
            updated = updated.copyWith(rating: rate);
          }
          widget.spots[index] = updated;
        }
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Фильтры применены ко всем ${filtered.length} спотам')),
    );
  }

  Future<void> _deleteFiltered(List<TrainingSpot> filtered) async {
    if (filtered.isEmpty || widget.onRemove == null) return;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить ${filtered.length} спотов?'),
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
    if (confirm != true) return;
    final indices = filtered
        .map((s) => widget.spots.indexOf(s))
        .where((i) => i != -1)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    for (final i in indices) {
      widget.onRemove!(i);
    }
    setState(() {
      _selectedSpots.removeAll(filtered);
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Удалено ${filtered.length} спотов')),
    );
  }

  Future<void> _addTagsToFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    final suggestions = <String>{
      ...TrainingSpotListState._availableTags,
      for (final list in TrainingSpotListState._tagPresets.values) ...list,
      for (final list in _customTagPresets.values) ...list,
      for (final s in widget.spots) ...s.tags,
    }..removeWhere((e) => e.isEmpty);

    final addTags = <String>{};
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(
              'Метки для $count спотов',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Тег',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    onSubmitted: (value) {
                      final tag = value.trim();
                      if (tag.isEmpty) return;
                      setStateDialog(() {
                        addTags.add(tag);
                      });
                      controller.clear();
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final tag in (suggestions.toList()..sort()))
                        InputChip(
                          label: Text(tag),
                          onPressed: () {
                            setStateDialog(() {
                              addTags.add(tag);
                            });
                          },
                        ),
                      for (final tag in addTags.toList()..sort())
                        Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setStateDialog(() {
                              addTags.remove(tag);
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
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Добавить'),
              ),
            ],
          );
        });
      },
    );

    if (confirmed != true || addTags.isEmpty) return;

    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index == -1) continue;
        final tags = <String>{...spot.tags}..addAll(addTags);
        final sorted = tags.toList()..sort();
        widget.spots[index] = spot.copyWith(tags: sorted);
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Добавлено ${addTags.length} тегов к $count спотам')),
    );
  }

  Future<void> _removeTagsFromFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    final allTags = <String>{};
    for (final spot in filtered) {
      allTags.addAll(spot.tags);
    }

    final removeTags = <String>{};

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(
              'Удалить теги у $count спотов',
              style: const TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final tag in (allTags.toList()..sort()))
                      CheckboxListTile(
                        value: removeTags.contains(tag),
                        title: Text(tag, style: const TextStyle(color: Colors.white)),
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v ?? false) {
                              removeTags.add(tag);
                            } else {
                              removeTags.remove(tag);
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),
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
          );
        });
      },
    );

    if (confirmed != true || removeTags.isEmpty) return;

    int updated = 0;
    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index == -1) continue;
        final tags = List<String>.from(spot.tags);
        final before = tags.length;
        tags.removeWhere(removeTags.contains);
        if (tags.length != before) {
          widget.spots[index] = spot.copyWith(tags: tags);
          updated++;
        }
      }
    });
    if (updated == 0) return;
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Теги удалены у $updated спотов')),
    );
  }

  Future<void> _setDifficultyForFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    int selected = 3;
    final int? result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(
              'Сложность для $count спотов',
              style: const TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 1; i <= 5; i++)
                  RadioListTile<int>(
                    value: i,
                    groupValue: selected,
                    title: Text('$i', style: const TextStyle(color: Colors.white)),
                    onChanged: (v) => setStateDialog(() => selected = v ?? selected),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Применить'),
              ),
            ],
          );
        });
      },
    );

    if (result == null) return;

    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          widget.spots[index] = spot.copyWith(difficulty: result);
        }
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Сложность $result выставлена для $count спотов')),
    );
  }

  Future<void> _setRatingForFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    int selected = 3;
    final int? result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: const Text(
              'Рейтинг для \$count спотов',
              style: TextStyle(color: Colors.white),
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= selected ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setStateDialog(() => selected = i),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Применить'),
              ),
            ],
          );
        });
      },
    );

    if (result == null) return;

    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          widget.spots[index] = spot.copyWith(rating: result);
        }
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Рейтинг \$result поставлен для \$count спотов')),
    );
  }

  Future<void> _setCommentForFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    final controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Комментарий для \$count спотов',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Комментарий',
              labelStyle: TextStyle(color: Colors.white),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          widget.spots[index] =
              spot.copyWith(userComment: result.isEmpty ? null : result);
        }
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Комментарий обновлен у \$count спотов')),
    );
  }

  Future<void> _setActionHistoryForFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    final controller = TextEditingController();

    final String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'История действий для \$count спотов',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: TextField(
                controller: controller,
                maxLines: null,
                minLines: 5,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'История действий',
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() {
      for (final spot in filtered) {
        final index = widget.spots.indexOf(spot);
        if (index != -1) {
          widget.spots[index] =
              spot.copyWith(actionHistory: result.isEmpty ? null : result);
        }
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('История действий обновлена у \$count спотов')),
    );
  }

  Future<void> _createPackFromFiltered(List<TrainingSpot> filtered) async {
    final count = filtered.length;
    if (count == 0) return;

    final controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Название пакета',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Название',
            labelStyle: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    await _exportNamedPack(filtered, name);
  }

  Widget _buildRatingStars(TrainingSpot spot, {bool highlight = false}) {
    return Row(
      children: [
        for (int i = 1; i <= 5; i++)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              i <= spot.rating ? Icons.star : Icons.star_border,
              color: highlight ? AppColors.accent : Colors.amber,
              size: 20,
            ),
            onPressed: () => _updateRating(spot, i),
          ),
      ],
    );
  }

  Widget _buildDifficultyDropdown(TrainingSpot spot, {bool highlight = false}) {
    return DropdownButton<int>(
      value: spot.difficulty,
      underline: const SizedBox(),
      dropdownColor: AppColors.cardBackground,
      style: TextStyle(
        color: Colors.white,
        fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
      ),
      items: [for (int i = 1; i <= 5; i++) DropdownMenuItem(value: i, child: Text('$i'))],
      onChanged: (v) {
        if (v != null) _updateDifficulty(spot, v);
      },
    );
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

  Future<void> _editTagsForSelected() async {
    final count = _selectedSpots.length;
    if (count == 0) return;

    final allTags = <String>{};
    for (final spot in _selectedSpots) {
      allTags.addAll(spot.tags);
    }

    final suggestions = <String>{
      ...TrainingSpotListState._availableTags,
      for (final list in TrainingSpotListState._tagPresets.values) ...list,
      for (final list in _customTagPresets.values) ...list,
      for (final s in widget.spots) ...s.tags,
    }..removeWhere((e) => e.isEmpty);

    final addTags = <String>{};
    final removeTags = <String>{};
    final TextEditingController controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(
              'Метки для $count спотов',
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Добавить теги',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Тег',
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    onSubmitted: (value) {
                      final tag = value.trim();
                      if (tag.isEmpty) return;
                      setStateDialog(() {
                        addTags.add(tag);
                      });
                      controller.clear();
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final tag in (suggestions.toList()..sort()))
                        InputChip(
                          label: Text(tag),
                          onPressed: () {
                            setStateDialog(() {
                              addTags.add(tag);
                            });
                          },
                        ),
                      for (final tag in addTags.toList()..sort())
                        Chip(
                          label: Text(tag),
                          onDeleted: () {
                            setStateDialog(() {
                              addTags.remove(tag);
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Удалить теги',
                      style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    width: 300,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final tag in (allTags.toList()..sort()))
                          CheckboxListTile(
                            value: removeTags.contains(tag),
                            title:
                                Text(tag, style: const TextStyle(color: Colors.white)),
                            onChanged: (v) {
                              setStateDialog(() {
                                if (v ?? false) {
                                  removeTags.add(tag);
                                } else {
                                  removeTags.remove(tag);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Применить'),
              ),
            ],
          );
        });
      },
    );

    if (confirmed != true) return;

    setState(() {
      for (final spot in _selectedSpots) {
        final index = widget.spots.indexOf(spot);
        if (index == -1) continue;
        final tags = <String>{...spot.tags};
        tags.addAll(addTags);
        tags.removeAll(removeTags);
        final sorted = tags.toList()..sort();
        widget.spots[index] = spot.copyWith(tags: sorted);
      }
    });
    widget.onChanged?.call();
    _saveOrderToPrefs();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Теги обновлены у $count спотов')),
    );
  }

  Future<void> _exportSelected() async {
    final spots = _selectedSpots.toList();
    if (spots.isEmpty) return;
    await _exportCsv(
      spots,
      successMessage: 'Экспортировано ${spots.length} выбранных спотов в CSV',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadMistakeIds();
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _currentFilteredSpots();

    return DropTarget(
      onDragDone: _handleDrop,
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchField(),
                const SizedBox(height: 4),
                _QuickPresetRow(
                  active: _activeQuickPreset,
                  onChanged: (value) {
                    setState(() {
                      if (value != null) {
                        if (_activeQuickPreset == null) {
                          _prevQuickTags = Set<String>.from(_selectedTags);
                        }
                        _activeQuickPreset = value;
                        final tag = _quickFilterPresets[value];
                        if (tag != null) {
                          _selectedTags
                            ..clear()
                            ..add(tag);
                        }
                      } else if (_activeQuickPreset != null) {
                        _selectedTags
                          ..clear()
                          ..addAll(_prevQuickTags ?? {});
                        _activeQuickPreset = null;
                        _prevQuickTags = null;
                      }
                    });
                    _savePresets();
                  },
                ),
                _buildFilterSummary(),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _createPackFromFiltered(filtered),
                    child: const Text('Создать пакет из отфильтрованных'),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _removeTagsFromFiltered(filtered),
                    child: const Text('Удалить тег у всех'),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _setDifficultyForFiltered(filtered),
                    child: const Text('Выставить сложность'),
                  ),
                ),
                const SizedBox(height: 4),
                _BatchFilterActions(
                  disabled: !_hasActiveFilters || filtered.isEmpty,
                  onApply: () => _applyActiveFiltersToFiltered(filtered),
                  onDelete: () => _deleteFiltered(filtered),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _setCommentForFiltered(filtered),
                    child: const Text('Редактировать комментарий для всех'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _setActionHistoryForFiltered(filtered),
                    child: const Text('Редактировать действия для всех'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _addTagsToFiltered(filtered),
                    child: const Text('Добавить тег ко всем'),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _setRatingForFiltered(filtered),
                    child: const Text('Поставить рейтинг'),
                  ),
                ),
                _buildIcmSwitch(),
                _buildRatedSwitch(),
                _buildMistakeSwitch(),
                const SizedBox(height: 8),
                _buildFilterToggleButton(),
                if (_tagFiltersExpanded) ...[
                  const SizedBox(height: 8),
                  _TagFilterSection(
                    filtered: filtered,
                    selectedTags: _selectedTags,
                    expanded: _tagFiltersExpanded,
                    selectedPreset: _selectedPreset,
                    customPresets: _customTagPresets,
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
                      final tags = TrainingSpotListState._tagPresets[value] ??
                          _customTagPresets[value];
                      if (tags == null) return;
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
                    onOpenSelector: _showTagSelector,
                    onManagePresets: _manageTagPresets,
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
                    onExportSelected: _exportSelected,
                    onEditTags: _editTagsForSelected,
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
                          const Text('Ручной порядок',
                              style: TextStyle(color: Colors.white)),
                          Switch(
                            value: _manualOrder,
                            onChanged: (v) {
                              if (v) {
                                _resetSort();
                              } else {
                                if (_sortOption != null) {
                                  _sortFiltered(
                                      _currentFilteredSpots(), _sortOption!);
                                } else if (_ratingSort != null) {
                                  _sortByRating(
                                      _currentFilteredSpots(), _ratingSort!);
                                } else if (_simpleSortField != null) {
                                  _applySimpleSort(_currentFilteredSpots());
                                } else if (_listSort != null) {
                                  _applyListSort(_currentFilteredSpots());
                                } else if (_quickSort != null) {
                                  _applyQuickSort(_currentFilteredSpots());
                                } else {
                                  _sortOption = SortOption.buyInAsc;
                                  _sortFiltered(
                                      _currentFilteredSpots(), _sortOption!);
                                }
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
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: clearFilters,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Очистить фильтры'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildListHeader(),
                const SizedBox(height: 12),
                _buildPackSummary(filtered),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverFilterBarDelegate(
              height: 140,
              child: _FilterBar(
                selectedTags: _selectedTags,
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
                difficultyFilters: _difficultyFilters,
                onDifficultyChanged: (value) {
                  setState(() {
                    if (_difficultyFilters.contains(value)) {
                      _difficultyFilters.remove(value);
                    } else {
                      _difficultyFilters.add(value);
                    }
                  });
                  _savePresets();
                },
                onDifficultyToggleAll: () {
                  setState(() {
                    if (_difficultyFilters.length == 5) {
                      _difficultyFilters.clear();
                    } else {
                      _difficultyFilters
                        ..clear()
                        ..addAll({1, 2, 3, 4, 5});
                    }
                  });
                  _savePresets();
                },
                ratingFilters: _ratingFilters,
                onRatingChanged: (value) {
                  setState(() {
                    if (_ratingFilters.contains(value)) {
                      _ratingFilters.remove(value);
                    } else {
                      _ratingFilters.add(value);
                    }
                  });
                  _savePresets();
                },
                onRatingToggleAll: () {
                  setState(() {
                    if (_ratingFilters.length == 5) {
                      _ratingFilters.clear();
                    } else {
                      _ratingFilters
                        ..clear()
                        ..addAll({1, 2, 3, 4, 5});
                    }
                  });
                  _savePresets();
                },
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverSortHeaderDelegate(
              height: 40,
              child: _buildSortHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _listVisible
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                _QuickSortSegment(
                  value: _quickSort,
                  onChanged: (v) {
                    setState(() => _quickSort = v);
                    _applyQuickSort(filtered);
                  },
                ),
                const SizedBox(height: 8),
                _ListSortDropdown(
                  value: _listSort,
                  filtered: filtered,
                  manualOrder: _manualOrder,
                  onChanged: (value, spots) {
                    if (value == null) {
                      _resetSort();
                    } else {
                      setState(() => _listSort = value);
                      _applyListSort(spots);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _RatingSortDropdown(
                  order: _ratingSort,
                  filtered: filtered,
                  manualOrder: _manualOrder,
                  onChanged: (value, spots) {
                    if (value == null) {
                      _resetSort();
                    } else {
                      _sortByRating(spots, value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _SimpleSortRow(
                  field: _simpleSortField,
                  order: _simpleSortOrder,
                  onFieldChanged: (value) {
                    setState(() {
                      _simpleSortField = value;
                      _manualOrder = value == null;
                    });
                    if (value == null) {
                      _resetSort();
                    } else {
                      _applySimpleSort(filtered);
                    }
                  },
                  onOrderChanged: (order) {
                    setState(() => _simpleSortOrder = order);
                    if (_simpleSortField != null) {
                      _applySimpleSort(filtered);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _buildVisibleSummary(filtered),
                _buildHideCompletedSwitch(),
                _buildMistakeSwitch(),
                const SizedBox(height: 8),
                _ApplyDifficultyDropdown(
                  onChanged: (value) {
                    if (value == null) return;
                    _applyDifficultyToFiltered(value);
                  },
                ),
                const SizedBox(height: 8),
                _ApplyRatingDropdown(
                  onChanged: (value) {
                    if (value == null) return;
                    _applyRatingToFiltered(value);
                  },
                ),
                const SizedBox(height: 8),
                if (_listVisible)
                  if (filtered.isEmpty)
                    SizedBox(
                      height: 150,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.spots.isEmpty
                                  ? Icons.folder_open
                                  : Icons.sentiment_dissatisfied,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.spots.isEmpty
                                  ? 'Нет импортированных спотов. Загрузите пакет, чтобы начать.'
                                  : 'Нет подходящих спотов',
                              style: const TextStyle(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
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
                                return ReorderableDelayedDragStartListener(
                                  key: ValueKey(spot),
                                  index: index,
                                  child: Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBackground,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.drag_handle,
                                            color: Colors.white70),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (spot.tournamentId != null &&
                                                  spot.tournamentId!.isNotEmpty)
                                                GestureDetector(
                                                  onTap: () =>
                                                      _editTitleAndTags(spot),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text.rich(
                                                          _highlightSpan(
                                                              'ID: ${spot.tournamentId}'),
                                                          style: _quickSort ==
                                                                  QuickSortOption.id
                                                              ? const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)
                                                              : null,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      _buildDifficultyDropdown(
                                                          spot,
                                                          highlight: _quickSort ==
                                                              QuickSortOption.difficulty),
                                                    ],
                                                  ),
                                                )
                                              else
                                                _buildDifficultyDropdown(
                                                    spot,
                                                    highlight: _quickSort ==
                                                        QuickSortOption.difficulty),
                                              if (spot.buyIn != null)
                                                Text('Buy-In: ${spot.buyIn}',
                                                    style: const TextStyle(
                                                        color: Colors.white)),
                                              if (spot.gameType != null &&
                                                  spot.gameType!.isNotEmpty)
                                                Text('Game: ${spot.gameType}',
                                                    style: const TextStyle(
                                                        color: Colors.white)),
                                              const SizedBox(height: 8),
                                              GestureDetector(
                                                onTap: () =>
                                                    _editTitleAndTags(spot),
                                            child: Wrap(
                                                spacing: 4,
                                                children: [
                                                    if (spot.tags.isEmpty)
                                                      const Text('Без тегов',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white54))
                                                    else
                                                      for (final tag in spot.tags)
                                                        Chip(
                                                          label:
                                                              Text.rich(
                                                                  _highlightSpan(
                                                                      tag)),
                                                          backgroundColor: AppColors
                                                              .cardBackground,
                                                        ),
                                                  ],
                                                ),
                                              ),
                                              if (spot.userComment != null &&
                                                  spot.userComment!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 4),
                                                  child: Builder(builder: (context) {
                                                    var txt = spot.userComment!
                                                        .replaceAll('\n', ' ');
                                                    if (txt.length > 80) {
                                                      txt = '${txt.substring(0, 80)}…';
                                                    }
                                                    return Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('📝',
                                                            style: TextStyle(
                                                                color: Colors.white70)),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text.rich(
                                                            _highlightSpan(txt),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                ),
                                              if (spot.actionHistory != null &&
                                                  spot.actionHistory!.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Builder(builder: (context) {
                                                    var txt = spot.actionHistory!
                                                        .replaceAll('\n', ' ');
                                                    if (txt.length > 80) {
                                                      txt = '${txt.substring(0, 80)}…';
                                                    }
                                                    return Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('⚔️',
                                                            style: TextStyle(color: Colors.white70)),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text.rich(_highlightSpan(txt)),
                                                        ),
                                                      ],
                                                    );
                                                  }),
                                                ),
                                                _buildRatingStars(
                                                    spot,
                                                    highlight: _quickSort ==
                                                        QuickSortOption.rating),
                                              IconButton(
                                                icon: const Icon(Icons.label_outline,
                                                    color: Colors.white70),
                                                tooltip: 'Редактировать теги',
                                                onPressed: () => _editTagsForSpot(spot),
                                              ),
                                              TextButton(
                                                onPressed: () => _quickAddTagsForSpot(spot),
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                ),
                                                child: const Text(
                                                  '+Тег',
                                                  style: TextStyle(color: Colors.white70),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.onEdit != null)
                                          IconButton(
                                            icon: const Icon(Icons.edit_square,
                                                color: Colors.white70),
                                            onPressed: () => widget.onEdit!(
                                                widget.spots.indexOf(spot)),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.white70),
                                          onPressed: () => _editComment(spot),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.history,
                                              color: Colors.white70),
                                          onPressed: () => _editActionHistory(spot),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy,
                                              color: Colors.white70),
                                          onPressed: () => _duplicateSpot(spot),
                                        ),
                                        IconButton(
                                          icon: const Text('⚔️',
                                              style: TextStyle(fontSize: 18)),
                                          tooltip: 'Анализ',
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TrainingSpotAnalysisScreen(
                                                        spot: spot),
                                              ),
                                            );
                                          },
                                        ),
                                        if (widget.onRemove != null)
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () => _deleteSpot(spot),
                                          ),
                                      ],
                                    ),
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
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (spot.tournamentId != null &&
                                                spot.tournamentId!.isNotEmpty)
                                              GestureDetector(
                                                onTap: () =>
                                                    _editTitleAndTags(spot),
                                                child: Row(
                                                  children: [
                                                      Expanded(
                                                        child: Text.rich(
                                                          _highlightSpan(
                                                              'ID: ${spot.tournamentId}'),
                                                          style: _quickSort ==
                                                                  QuickSortOption.id
                                                              ? const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)
                                                              : null,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      _buildDifficultyDropdown(
                                                          spot,
                                                          highlight: _quickSort ==
                                                              QuickSortOption.difficulty),
                                                  ],
                                                ),
                                              )
                                              else
                                                _buildDifficultyDropdown(
                                                    spot,
                                                    highlight: _quickSort ==
                                                        QuickSortOption.difficulty),
                                            if (spot.buyIn != null)
                                              Text('Buy-In: ${spot.buyIn}',
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            if (spot.gameType != null &&
                                                spot.gameType!.isNotEmpty)
                                              Text('Game: ${spot.gameType}',
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () =>
                                                  _editTitleAndTags(spot),
                                              child: Wrap(
                                                spacing: 4,
                                                children: [
                                                  if (spot.tags.isEmpty)
                                                    const Text('Без тегов',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white54))
                                                  else
                                                    for (final tag in spot.tags)
                                                      Chip(
                                                        label: Text.rich(
                                                            _highlightSpan(tag)),
                                                        backgroundColor:
                                                            AppColors.cardBackground,
                                                      ),
                                                ],
                                                ),
                                            ),
                                            if (spot.userComment != null &&
                                                spot.userComment!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4),
                                                child: Builder(builder: (context) {
                                                  var txt = spot.userComment!
                                                      .replaceAll('\n', ' ');
                                                  if (txt.length > 80) {
                                                    txt = '${txt.substring(0, 80)}…';
                                                  }
                                                  return Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('📝',
                                                          style: TextStyle(color: Colors.white70)),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text.rich(
                                                          _highlightSpan(txt),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                            if (spot.actionHistory != null &&
                                                spot.actionHistory!.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Builder(builder: (context) {
                                                  var txt = spot.actionHistory!
                                                      .replaceAll('\n', ' ');
                                                  if (txt.length > 80) {
                                                    txt = '${txt.substring(0, 80)}…';
                                                  }
                                                  return Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const Text('⚔️',
                                                          style: TextStyle(color: Colors.white70)),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text.rich(
                                                          _highlightSpan(txt),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                              ),
                                              _buildRatingStars(
                                                  spot,
                                                  highlight:
                                                      _quickSort == QuickSortOption.rating),
                                            IconButton(
                                              icon: const Icon(Icons.label_outline,
                                                  color: Colors.white70),
                                              tooltip: 'Редактировать теги',
                                              onPressed: () => _editTagsForSpot(spot),
                                            ),
                                            TextButton(
                                              onPressed: () => _quickAddTagsForSpot(spot),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: const Text(
                                                '+Тег',
                                                style: TextStyle(color: Colors.white70),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (widget.onEdit != null)
                                        IconButton(
                                          icon: const Icon(Icons.edit_square,
                                              color: Colors.white70),
                                          onPressed: () => widget.onEdit!(
                                              widget.spots.indexOf(spot)),
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.white70),
                                        onPressed: () => _editComment(spot),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history,
                                            color: Colors.white70),
                                        onPressed: () => _editActionHistory(spot),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.copy,
                                            color: Colors.white70),
                                        onPressed: () => _duplicateSpot(spot),
                                      ),
                                      IconButton(
                                        icon: const Text('⚔️',
                                            style: TextStyle(fontSize: 18)),
                                        tooltip: 'Анализ',
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  TrainingSpotAnalysisScreen(
                                                      spot: spot),
                                            ),
                                          );
                                        },
                                      ),
                                      if (widget.onRemove != null)
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteSpot(spot),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed:
                            filtered.isEmpty ? null : () => _exportPack(filtered),
                        child: const Text('Экспортировать пакет'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            filtered.isEmpty ? null : () => _exportCsv(filtered),
                        child: const Text('Скачать CSV'),
                      ),
                    ],
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: filtered.isEmpty
                          ? null
                          : () => _exportPackSummary(filtered),
                      child: const Text('Export Spot Summary'),
                    ),
                  ),
                ],
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
          ),
        ],
      ),
    );
        _RatingSortDropdown(
          order: _ratingSort,
          filtered: filtered,
          manualOrder: _manualOrder,
          onChanged: (value, spots) {
            if (value == null) {
              _resetSort();
            } else {
              _sortByRating(spots, value);
            }
          },
        ),
        const SizedBox(height: 8),
        _buildVisibleSummary(filtered),
        _buildHideCompletedSwitch(),
        _buildMistakeSwitch(),
        const SizedBox(height: 8),
        _ApplyDifficultyDropdown(
          onChanged: (value) {
            if (value == null) return;
            _applyDifficultyToFiltered(value);
          },
        ),
        const SizedBox(height: 8),
        _ApplyRatingDropdown(
          onChanged: (value) {
            if (value == null) return;
            _applyRatingToFiltered(value);
          },
        ),
        const SizedBox(height: 8),
        if (_listVisible)
          if (filtered.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.spots.isEmpty
                          ? Icons.folder_open
                          : Icons.sentiment_dissatisfied,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.spots.isEmpty
                          ? 'Нет импортированных спотов. Загрузите пакет, чтобы начать.'
                          : 'Нет подходящих спотов',
                      style: const TextStyle(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
                      return ReorderableDelayedDragStartListener(
                        key: ValueKey(spot),
                        index: index,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.drag_handle, color: Colors.white70),
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
                                child: Row(
                                  children: [
                                      Expanded(
                                        child: Text.rich(
                                          _highlightSpan('ID: ${spot.tournamentId}'),
                                          style: _quickSort == QuickSortOption.id
                                              ? const TextStyle(fontWeight: FontWeight.bold)
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      _buildDifficultyDropdown(
                                          spot,
                                          highlight:
                                              _quickSort == QuickSortOption.difficulty),
                                  ],
                                ),
                              ),
                              else
                                _buildDifficultyDropdown(
                                    spot,
                                    highlight:
                                        _quickSort == QuickSortOption.difficulty),
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
                                        label: Text.rich(_highlightSpan(tag)),
                                        backgroundColor: AppColors.cardBackground,
                                      ),
                                ],
                              ),
                            ),
                              _buildRatingStars(
                                  spot,
                                  highlight:
                                      _quickSort == QuickSortOption.rating),
                            IconButton(
                              icon: const Icon(Icons.label_outline,
                                  color: Colors.white70),
                              tooltip: 'Редактировать теги',
                              onPressed: () => _editTagsForSpot(spot),
                            ),
                            TextButton(
                              onPressed: () => _quickAddTagsForSpot(spot),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                              ),
                        child: const Text(
                          '+Тег',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Colors.white70),
                    onPressed: () =>
                        widget.onEdit!(widget.spots.indexOf(spot)),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => _editComment(spot),
                ),
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white70),
                        onPressed: () => _editActionHistory(spot),
                      ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white70),
                            onPressed: () => _duplicateSpot(spot),
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
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text.rich(
                                              _highlightSpan('ID: ${spot.tournamentId}'),
                                              style: _quickSort == QuickSortOption.id
                                                  ? const TextStyle(fontWeight: FontWeight.bold)
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                            _buildDifficultyDropdown(
                                                spot,
                                                highlight:
                                                    _quickSort == QuickSortOption.difficulty),
                                        ],
                                      ),
                                    )
                                    else
                                      _buildDifficultyDropdown(
                                          spot,
                                          highlight:
                                              _quickSort == QuickSortOption.difficulty),
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
                                              label: Text.rich(_highlightSpan(tag)),
                                              backgroundColor: AppColors.cardBackground,
                                            ),
                                      ],
                                    ),
                                  ),
                                    _buildRatingStars(
                                        spot,
                                        highlight:
                                            _quickSort == QuickSortOption.rating),
                                  IconButton(
                                  icon: const Icon(Icons.label_outline,
                                      color: Colors.white70),
                                  tooltip: 'Редактировать теги',
                                  onPressed: () => _editTagsForSpot(spot),
                                ),
                                TextButton(
                                  onPressed: () => _quickAddTagsForSpot(spot),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    '+Тег',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white70),
                            onPressed: () => _editComment(spot),
                          ),
                          IconButton(
                            icon: const Icon(Icons.history, color: Colors.white70),
                            onPressed: () => _editActionHistory(spot),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Colors.white70),
                            onPressed: () => _duplicateSpot(spot),
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
          child: Row(
            children: [
              ElevatedButton(
                onPressed:
                    filtered.isEmpty ? null : () => _exportPack(filtered),
                child: const Text('Экспортировать пакет'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    filtered.isEmpty ? null : () => _exportCsv(filtered),
                child: const Text('Скачать CSV'),
              ),
            ],
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: filtered.isEmpty
                  ? null
                  : () => _exportPackSummary(filtered),
              child: const Text('Export Spot Summary'),
            ),
          ),
        ],
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
          SliverToBoxAdapter(
            child: SizedBox(height: _hasActiveFilters ? 72 : 0),
          ),
        ],
      ),
      Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSlide(
            offset: _hasActiveFilters ? Offset.zero : const Offset(0, 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: AppColors.cardBackground,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: clearFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Сбросить фильтры'),
                ),
              ),
            ),
          ),
        ),
    )
  }

  Widget _buildSearchField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onTap: () => _showSearchHistoryDropdown(context),
            onSubmitted: (value) => _addToSearchHistory(value),
            decoration: InputDecoration(
              hintText: 'Поиск по ID или тегу...',
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

  Widget _buildVisibleSummary(List<TrainingSpot> filtered) {
    return Text(
      'Показано: ${filtered.length} спотов из ${widget.spots.length}',
      style: const TextStyle(color: Colors.grey),
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

  Widget _buildRatedSwitch() {
    return SwitchListTile(
      value: _ratedOnly,
      onChanged: (v) {
        setState(() => _ratedOnly = v);
        _savePresets();
      },
      title: const Text('Только с оценкой',
          style: TextStyle(color: Colors.white)),
      activeColor: Colors.orange,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildHideCompletedSwitch() {
    return SwitchListTile(
      value: _hideCompleted,
      onChanged: (v) {
        setState(() => _hideCompleted = v);
        _savePresets();
      },
      title:
          const Text('Скрыть завершённые', style: TextStyle(color: Colors.white)),
      activeColor: Colors.orange,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildMistakeSwitch() {
    return SwitchListTile(
      value: _mistakesOnly,
      onChanged: (v) {
        setState(() => _mistakesOnly = v);
        _savePresets();
      },
      title:
          const Text('Повторить ошибки', style: TextStyle(color: Colors.white)),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tagFiltersExpanded ? 'Скрыть фильтры' : 'Показать фильтры',
            ),
            if (_hasActiveFilters)
              const Padding(
                padding: EdgeInsets.only(left: 4.0),
                child: _PulsingIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildListHeader() {
    return InkWell(
      onTap: () {
        setState(() => _listVisible = !_listVisible);
        _savePresets();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Список спотов',
              style: TextStyle(color: Colors.white),
            ),
            Icon(
              _listVisible ? Icons.expand_less : Icons.expand_more,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  String _currentSortFieldLabel() {
    if (_quickSort != null) {
      switch (_quickSort!) {
        case QuickSortOption.id:
          return 'ID';
        case QuickSortOption.difficulty:
          return 'Сложность';
        case QuickSortOption.rating:
          return 'Рейтинг';
      }
    }
    if (_listSort != null) {
      switch (_listSort!) {
        case ListSortOption.dateNew:
        case ListSortOption.dateOld:
          return 'Дата';
        case ListSortOption.rating:
          return 'Рейтинг';
        case ListSortOption.difficulty:
          return 'Сложность';
        case ListSortOption.comment:
          return 'Комментарий';
      }
    }
    if (_simpleSortField != null) {
      switch (_simpleSortField!) {
        case SimpleSortField.createdAt:
          return 'Дата';
        case SimpleSortField.difficulty:
          return 'Сложность';
        case SimpleSortField.rating:
          return 'Рейтинг';
      }
    }
    if (_ratingSort != null) {
      return 'Рейтинг';
    }
    if (_sortOption != null) {
      switch (_sortOption!) {
        case SortOption.buyInAsc:
        case SortOption.buyInDesc:
          return 'Buy-In';
        case SortOption.gameType:
          return 'Тип игры';
        case SortOption.tournamentId:
          return 'ID';
        case SortOption.difficultyAsc:
        case SortOption.difficultyDesc:
          return 'Сложность';
      }
    }
    return 'Ручной порядок';
  }

  SimpleSortOrder? _currentSortOrder() {
    if (_simpleSortField != null) {
      return _simpleSortOrder;
    }
    if (_ratingSort != null) {
      return _ratingSort == RatingSortOrder.highFirst
          ? SimpleSortOrder.descending
          : SimpleSortOrder.ascending;
    }
    if (_listSort != null) {
      switch (_listSort!) {
        case ListSortOption.dateNew:
        case ListSortOption.rating:
        case ListSortOption.difficulty:
          return SimpleSortOrder.descending;
        case ListSortOption.dateOld:
        case ListSortOption.comment:
          return SimpleSortOrder.ascending;
      }
    }
    if (_quickSort != null) {
      switch (_quickSort!) {
        case QuickSortOption.rating:
          return SimpleSortOrder.descending;
        case QuickSortOption.id:
        case QuickSortOption.difficulty:
          return SimpleSortOrder.ascending;
      }
    }
    if (_sortOption != null) {
      switch (_sortOption!) {
        case SortOption.buyInAsc:
        case SortOption.gameType:
        case SortOption.tournamentId:
        case SortOption.difficultyAsc:
          return SimpleSortOrder.ascending;
        case SortOption.buyInDesc:
        case SortOption.difficultyDesc:
          return SimpleSortOrder.descending;
      }
    }
    return null;
  }

  Widget _buildSortHeader() {
    final order = _currentSortOrder();
    final arrow = order == null
        ? null
        : order == SimpleSortOrder.ascending
            ? '↑'
            : '↓';
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Сортировка: ${_currentSortFieldLabel()}',
            style: const TextStyle(color: Colors.white),
          ),
          if (arrow != null) ...[
            const SizedBox(width: 4),
            Text(arrow, style: const TextStyle(color: Colors.white)),
          ]
        ],
      ),
    );
  }


  /// Reset all active filters and sorting options.
  void clearFilters() {
    _lastFilterState = FilterState(
      searchText: _searchController.text,
      selectedTags: Set<String>.from(_selectedTags),
      difficultyFilters: Set<int>.from(_difficultyFilters),
      ratingFilters: Set<int>.from(_ratingFilters),
      icmOnly: _icmOnly,
      ratedOnly: _ratedOnly,
    );
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _selectedPreset = null;
      _activeQuickPreset = null;
      _prevQuickTags = null;
      _icmOnly = false;
      _ratedOnly = false;
      _difficultyFilters.clear();
      _ratingFilters.clear();
    });
    final bool hadSort = _sortOption != null;
    _resetSort();
    if (!hadSort) widget.onChanged?.call();
    _savePresets();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Фильтры сброшены'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () {
              final prev = _lastFilterState;
              if (prev != null) {
                _restoreFilterState(prev);
              }
            },
          ),
        ),
      );
  }

  void _clearTagFilters() {
    setState(() {
      _selectedTags.clear();
      _selectedPreset = null;
      _activeQuickPreset = null;
      _prevQuickTags = null;
    });
    _savePresets();
  }

  Future<void> _showTagSelector() async {
    final local = Set<String>.from(_selectedTags);
    String? selectedPreset;
    final analytics = context.read<TrainingPackTagAnalyticsService>();
    final popular = [for (final a in analytics.getPopularTags()) a.tag];
    final tags = [
      for (final t in popular)
        if (_availableTags.contains(t)) t,
      ...[
        for (final t in _availableTags)
          if (!popular.contains(t)) t
      ]
    ];
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: const Text(
            'Выберите теги',
            style: TextStyle(color: Colors.white),
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final tag in tags)
                            CheckboxListTile(
                              value: local.contains(tag),
                              title:
                                  Text(tag, style: const TextStyle(color: Colors.white)),
                              onChanged: (checked) {
                                setStateDialog(() {
                                  if (checked ?? false) {
                                    local.add(tag);
                                  } else {
                                    local.remove(tag);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedPreset,
                            hint: const Text('Пресет',
                                style: TextStyle(color: Colors.white60)),
                            dropdownColor: AppColors.cardBackground,
                            style: const TextStyle(color: Colors.white),
                            items: [
                              for (final name in _customTagPresets.keys)
                                DropdownMenuItem(value: name, child: Text(name)),
                            ],
                            onChanged: (v) {
                              setStateDialog(() {
                                selectedPreset = v;
                                if (v != null) {
                                  local
                                    ..clear()
                                    ..addAll(_customTagPresets[v] ?? const []);
                                }
                              });
                            },
                          ),
                        ),
                        IconButton(
                          tooltip: 'Сохранить',
                          icon: const Icon(Icons.save, color: Colors.white),
                          onPressed: () async {
                            final controller =
                                TextEditingController(text: selectedPreset ?? '');
                            final name = await showDialog<String>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.cardBackground,
                                title: Text(
                                  selectedPreset == null
                                      ? 'Новый пресет'
                                      : 'Сохранить пресет',
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  style:
                                      const TextStyle(color: Colors.white),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Отмена'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(
                                        context, controller.text.trim()),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                            if (name != null && name.isNotEmpty) {
                              setStateDialog(() {
                                if (selectedPreset != null &&
                                    selectedPreset != name) {
                                  _customTagPresets.remove(selectedPreset);
                                }
                                _customTagPresets[name] = local.toList();
                                selectedPreset = name;
                              });
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Переименовать',
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: selectedPreset == null
                              ? null
                              : () async {
                                  final controller =
                                      TextEditingController(text: selectedPreset);
                                  final name = await showDialog<String>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppColors.cardBackground,
                                      title: const Text('Переименовать',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      content: TextField(
                                        controller: controller,
                                        autofocus: true,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Отмена'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                              context, controller.text.trim()),
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (name != null &&
                                      name.isNotEmpty &&
                                      name != selectedPreset) {
                                    setStateDialog(() {
                                      final tags =
                                          _customTagPresets.remove(selectedPreset);
                                      if (tags != null) {
                                        _customTagPresets[name] = tags;
                                        selectedPreset = name;
                                      }
                                    });
                                  }
                                },
                        ),
                        IconButton(
                          tooltip: 'Удалить',
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: selectedPreset == null
                              ? null
                              : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Удалить пресет "$selectedPreset"?'),
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
                                  if (confirm == true) {
                                    setStateDialog(() {
                                      _customTagPresets.remove(selectedPreset);
                                      selectedPreset = null;
                                    });
                                  }
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, local),
              child: const Text('Готово'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedTags
          ..clear()
          ..addAll(result);
      });
    }
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
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final s in spots) s.toJson()]);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/training_spots_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'training_spots.json');
  }

  Future<void> _exportNamedPack(List<TrainingSpot> spots, String name) async {
    if (spots.isEmpty) return;
    const encoder = JsonEncoder.withIndent('  ');
    final jsonStr = encoder.convert([for (final s in spots) s.toJson()]);
    final dir = await getTemporaryDirectory();
    final safe = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safe.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: '$safe.json');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Пакет "$name" создан, спотов: ${spots.length}')),
      );
    }
  }

  Future<void> _exportPackSummary(List<TrainingSpot> spots) async {
    if (spots.isEmpty) return;
    final buffer = StringBuffer();
    for (final spot in spots) {
      buffer.writeln(
          'ID: ${spot.tournamentId ?? '-'}, Buy-In: ${spot.buyIn ?? '-'}, Game: ${spot.gameType ?? '-'}, Tags: ${spot.tags.length}');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/spot_summary_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'spot_summary.txt');
  }

  Future<void> _exportCsv(List<TrainingSpot> spots,
      {String? successMessage}) async {
    if (spots.isEmpty) return;

    final rows = <List<dynamic>>[];
    rows.add(['ID', 'Difficulty', 'Rating', 'Tags', 'Buy-in', 'ICM', 'Date']);
    final today = DateTime.now();
    final dateStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final s in spots) {
      rows.add([
        s.tournamentId ?? '',
        s.difficulty,
        s.rating,
        s.tags.join(';'),
        s.buyIn ?? '',
        s.tags.contains('ICM') ? '1' : '0',
        dateStr,
      ]);
    }

    final csvStr = const ListToCsvConverter().convert(rows, eol: '\r\n');
    final bytes = Uint8List.fromList(utf8.encode(csvStr));
    final name = 'training_spots_${DateTime.now().millisecondsSinceEpoch}';
    try {
      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        ext: 'csv',
        mimeType: MimeType.csv,
      );
      if (mounted) {
        final msg = successMessage ??
            'Экспортировано ${spots.length} спотов в CSV';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ошибка экспорта CSV')));
      }
    }
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
            spots.add(TrainingSpot.fromJson(Map<String, dynamic>.from(e)));
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
      if (path.toLowerCase().endsWith('.json')) {
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
      case SortOption.difficultyAsc:
        sorted.sort(
          (a, b) => (a.difficulty).compareTo(b.difficulty),
        );
        break;
      case SortOption.difficultyDesc:
        sorted.sort(
          (a, b) => (b.difficulty).compareTo(a.difficulty),
        );
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

  void _sortByRating(List<TrainingSpot> filtered, RatingSortOrder order) {
    final indices = filtered.map((s) => widget.spots.indexOf(s)).toList();
    final sorted = List<TrainingSpot>.from(filtered);
    _originalOrder ??= List<TrainingSpot>.from(widget.spots);
    switch (order) {
      case RatingSortOrder.highFirst:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case RatingSortOrder.lowFirst:
        sorted.sort((a, b) => a.rating.compareTo(b.rating));
        break;
    }
    setState(() {
      for (int i = 0; i < indices.length; i++) {
        widget.spots[indices[i]] = sorted[i];
      }
      _ratingSort = order;
      _sortOption = null;
      _manualOrder = false;
    });
    widget.onChanged?.call();
    _savePresets();
  }

  void _applySimpleSort(List<TrainingSpot> filtered) {
    if (_simpleSortField == null) return;
    final indices = filtered.map((s) => widget.spots.indexOf(s)).toList();
    final sorted = List<TrainingSpot>.from(filtered);
    _originalOrder ??= List<TrainingSpot>.from(widget.spots);
    int compare(TrainingSpot a, TrainingSpot b) {
      int result;
      switch (_simpleSortField!) {
        case SimpleSortField.createdAt:
          result = a.createdAt.compareTo(b.createdAt);
          break;
        case SimpleSortField.difficulty:
          result = a.difficulty.compareTo(b.difficulty);
          break;
        case SimpleSortField.rating:
          result = a.rating.compareTo(b.rating);
          break;
      }
      return _simpleSortOrder == SimpleSortOrder.ascending ? result : -result;
    }
    sorted.sort(compare);
    setState(() {
      for (int i = 0; i < indices.length; i++) {
        widget.spots[indices[i]] = sorted[i];
      }
      _sortOption = null;
      _ratingSort = null;
      _manualOrder = false;
    });
    widget.onChanged?.call();
    _savePresets();
  }

  void _applyListSort(List<TrainingSpot> filtered) {
    if (_listSort == null) return;
    final indices = filtered.map((s) => widget.spots.indexOf(s)).toList();
    final sorted = List<TrainingSpot>.from(filtered);
    _originalOrder ??= List<TrainingSpot>.from(widget.spots);
    int compare(TrainingSpot a, TrainingSpot b) {
      switch (_listSort!) {
        case ListSortOption.dateNew:
          return b.createdAt.compareTo(a.createdAt);
        case ListSortOption.dateOld:
          return a.createdAt.compareTo(b.createdAt);
        case ListSortOption.rating:
          return b.rating.compareTo(a.rating);
        case ListSortOption.difficulty:
          return b.difficulty.compareTo(a.difficulty);
        case ListSortOption.comment:
          return (a.userComment ?? '').toLowerCase().compareTo(
              (b.userComment ?? '').toLowerCase());
      }
    }
    sorted.sort(compare);
    setState(() {
      for (int i = 0; i < indices.length; i++) {
        widget.spots[indices[i]] = sorted[i];
      }
      _sortOption = null;
      _ratingSort = null;
      _simpleSortField = null;
      _manualOrder = false;
    });
    widget.onChanged?.call();
    _savePresets();
  }

  void _applyQuickSort(List<TrainingSpot> filtered) {
    if (_quickSort == null) return;
    final indices = filtered.map((s) => widget.spots.indexOf(s)).toList();
    final sorted = List<TrainingSpot>.from(filtered);
    _originalOrder ??= List<TrainingSpot>.from(widget.spots);
    int compare(TrainingSpot a, TrainingSpot b) {
      switch (_quickSort!) {
        case QuickSortOption.id:
          return (a.tournamentId ?? '').compareTo(b.tournamentId ?? '');
        case QuickSortOption.difficulty:
          return a.difficulty.compareTo(b.difficulty);
        case QuickSortOption.rating:
          return b.rating.compareTo(a.rating);
      }
    }
    sorted.sort(compare);
    setState(() {
      for (int i = 0; i < indices.length; i++) {
        widget.spots[indices[i]] = sorted[i];
      }
      _sortOption = null;
      _ratingSort = null;
      _simpleSortField = null;
      _listSort = null;
      _manualOrder = false;
    });
    widget.onChanged?.call();
    _savePresets();
  }

  void _saveCurrentOrder() {
    setState(() {
      _originalOrder = List<TrainingSpot>.from(widget.spots);
      _sortOption = null;
      _ratingSort = null;
      _simpleSortField = null;
      _listSort = null;
      _quickSort = null;
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
    if (_sortOption == null &&
        _ratingSort == null &&
        _simpleSortField == null &&
        _listSort == null &&
        _quickSort == null) {
      return;
    }
    setState(() {
      if (_originalOrder != null &&
          widget.spots.length == _originalOrder!.length) {
        widget.spots.setAll(0, _originalOrder!);
      }
      _originalOrder = null;
      _sortOption = null;
      _ratingSort = null;
      _simpleSortField = null;
      _listSort = null;
      _quickSort = null;
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
  final Map<String, List<String>> customPresets;
  final ValueChanged<bool> onExpanded;
  final void Function(String tag, bool selected) onTagToggle;
  final ValueChanged<String?> onPresetSelected;
  final VoidCallback onClearTags;
  final VoidCallback onOpenSelector;
  final VoidCallback onManagePresets;

  const _TagFilterSection({
    required this.filtered,
    required this.selectedTags,
    required this.expanded,
    required this.selectedPreset,
    required this.customPresets,
    required this.onExpanded,
    required this.onTagToggle,
    required this.onPresetSelected,
    required this.onClearTags,
    required this.onOpenSelector,
    required this.onManagePresets,
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
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: onManagePresets,
            child: const Text('Редактировать пресеты'),
          ),
        ),
      ],
    );
  }

  Widget _buildTagFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final tag in selectedTags)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                label: Text(tag),
                selected: true,
                onSelected: (selected) => onTagToggle(tag, selected),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTagFilters() {
    final count = selectedTags.length;
    final label =
        count == 0 ? 'Выбрать теги' : 'Выбрано: $count';
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton(
        onPressed: onOpenSelector,
        child: Text(label),
      ),
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
            for (final entry in customPresets.entries)
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

class _DifficultyChipRow extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onChanged;
  final VoidCallback onToggleAll;

  const _DifficultyChipRow({
    required this.selected,
    required this.onChanged,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Сложность', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: [
            for (int i = 1; i <= 5; i++)
              FilterChip(
                label: Text('$i'),
                selected: selected.contains(i),
                onSelected: (_) => onChanged(i),
              ),
          ],
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onToggleAll,
          child: const Text('Выбрать все'),
        ),
      ],
    );
  }
}


class _RatingChipRow extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onChanged;
  final VoidCallback onToggleAll;

  const _RatingChipRow({
    required this.selected,
    required this.onChanged,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Рейтинг', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        Wrap(
          spacing: 4,
          children: [
            for (int i = 1; i <= 5; i++)
              FilterChip(
                label: Text('$i'),
                selected: selected.contains(i),
                onSelected: (_) => onChanged(i),
              ),
          ],
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onToggleAll,
          child: const Text('Выбрать все'),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onTagToggle;
  final Set<int> difficultyFilters;
  final ValueChanged<int> onDifficultyChanged;
  final VoidCallback onDifficultyToggleAll;
  final Set<int> ratingFilters;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onRatingToggleAll;

  const _FilterBar({
    required this.selectedTags,
    required this.onTagToggle,
    required this.difficultyFilters,
    required this.onDifficultyChanged,
    required this.onDifficultyToggleAll,
    required this.ratingFilters,
    required this.onRatingChanged,
    required this.onRatingToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final tag in selectedTags)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(tag),
                      selected: true,
                      onSelected: (selected) => onTagToggle(tag, selected),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _DifficultyChipRow(
            selected: difficultyFilters,
            onChanged: onDifficultyChanged,
            onToggleAll: onDifficultyToggleAll,
          ),
          const SizedBox(height: 8),
          _RatingChipRow(
            selected: ratingFilters,
            onChanged: onRatingChanged,
            onToggleAll: onRatingToggleAll,
          ),
        ],
      ),
    );
  }
}

class _SliverFilterBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _SliverFilterBarDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverFilterBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _SliverSortHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _SliverSortHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SliverSortHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _ApplyDifficultyDropdown extends StatelessWidget {
  final ValueChanged<int?> onChanged;

  const _ApplyDifficultyDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Применить сложность ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (int i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ApplyRatingDropdown extends StatelessWidget {
  final ValueChanged<int?> onChanged;

  const _ApplyRatingDropdown({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Применить рейтинг ко всем',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<int?>(
          hint: const Text('Выбрать', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: [
            for (int i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: onChanged,
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
        DropdownMenuItem(
          value: SortOption.difficultyAsc,
          child: Text('Сложность (по возрастанию)'),
        ),
        DropdownMenuItem(
          value: SortOption.difficultyDesc,
          child: Text('Сложность (по убыванию)'),
        ),
      ],
      onChanged:
          manualOrder ? null : (value) => onChanged(value, filtered),
    );
  }
}

class _ListSortDropdown extends StatelessWidget {
  final ListSortOption? value;
  final List<TrainingSpot> filtered;
  final bool manualOrder;
  final void Function(ListSortOption? value, List<TrainingSpot> spots) onChanged;

  const _ListSortDropdown({
    required this.value,
    required this.filtered,
    required this.manualOrder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Сортировка', style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<ListSortOption?>(
          value: value,
          hint:
              const Text('Без сортировки', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: null, child: Text('Без сортировки')),
            DropdownMenuItem(
                value: ListSortOption.dateNew,
                child: Text('Дата добавления (новые)')),
            DropdownMenuItem(
                value: ListSortOption.dateOld,
                child: Text('Дата добавления (старые)')),
            DropdownMenuItem(
                value: ListSortOption.rating, child: Text('Рейтинг')),
            DropdownMenuItem(
                value: ListSortOption.difficulty, child: Text('Сложность')),
            DropdownMenuItem(
                value: ListSortOption.comment, child: Text('Комментарий')),
          ],
          onChanged: manualOrder ? null : (v) => onChanged(v, filtered),
        ),
      ],
    );
  }
}

class _RatingSortDropdown extends StatelessWidget {
  final RatingSortOrder? order;
  final List<TrainingSpot> filtered;
  final bool manualOrder;
  final void Function(RatingSortOrder? value, List<TrainingSpot> spots)
      onChanged;

  const _RatingSortDropdown({
    required this.order,
    required this.filtered,
    required this.manualOrder,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Сортировать по рейтингу',
            style: TextStyle(color: Colors.white)),
        const SizedBox(width: 8),
        DropdownButton<RatingSortOrder?>(
          value: order,
          hint:
              const Text('Без сортировки', style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text('Без сортировки'),
            ),
            DropdownMenuItem(
              value: RatingSortOrder.highFirst,
              child: Text('Сначала высокий'),
            ),
            DropdownMenuItem(
              value: RatingSortOrder.lowFirst,
              child: Text('Сначала низкий'),
            ),
          ],
          onChanged: manualOrder ? null : (v) => onChanged(v, filtered),
        ),
      ],
    );
  }
}

class _QuickSortSegment extends StatelessWidget {
  final QuickSortOption? value;
  final ValueChanged<QuickSortOption> onChanged;

  const _QuickSortSegment({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Сортировать по', style: TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        ToggleButtons(
          isSelected: QuickSortOption.values
              .map((e) => e == value)
              .toList(),
          onPressed: (i) => onChanged(QuickSortOption.values[i]),
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('ID'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Сложность'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Рейтинг'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SimpleSortRow extends StatelessWidget {
  final SimpleSortField? field;
  final SimpleSortOrder order;
  final ValueChanged<SimpleSortField?> onFieldChanged;
  final ValueChanged<SimpleSortOrder> onOrderChanged;

  const _SimpleSortRow({
    required this.field,
    required this.order,
    required this.onFieldChanged,
    required this.onOrderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<SimpleSortField?>(
          value: field,
          hint: const Text('Сортировать по',
              style: TextStyle(color: Colors.white60)),
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(value: null, child: Text('Без сортировки')),
            DropdownMenuItem(
                value: SimpleSortField.createdAt, child: Text('Дата')),
            DropdownMenuItem(
                value: SimpleSortField.difficulty, child: Text('Сложность')),
            DropdownMenuItem(
                value: SimpleSortField.rating, child: Text('Рейтинг')),
          ],
          onChanged: onFieldChanged,
        ),
        const SizedBox(width: 8),
        DropdownButton<SimpleSortOrder>(
          value: order,
          dropdownColor: AppColors.cardBackground,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem(
                value: SimpleSortOrder.ascending,
                child: Text('По возрастанию')),
            DropdownMenuItem(
                value: SimpleSortOrder.descending,
                child: Text('По убыванию')),
          ],
          onChanged: (v) => onOrderChanged(v!),
        ),
      ],
    );
  }
}

class _SelectionActions extends StatelessWidget {
  final int selectedCount;
  final List<TrainingSpot> filtered;
  final void Function(List<TrainingSpot> spots) onSelectAll;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteSelected;
  final VoidCallback onExportSelected;
  final VoidCallback onEditTags;

  const _SelectionActions({
    required this.selectedCount,
    required this.filtered,
    required this.onSelectAll,
    required this.onClearSelection,
    required this.onDeleteSelected,
    required this.onExportSelected,
    required this.onEditTags,
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
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: selectedCount == 0 ? null : onExportSelected,
            child: const Text('Экспортировать выбранные'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: selectedCount == 0 ? null : onEditTags,
            icon: const Icon(Icons.label_outline),
            label: const Text('Метки'),
          ),
        ],
      ),
    );
  }
}

class _BatchFilterActions extends StatelessWidget {
  final bool disabled;
  final VoidCallback onApply;
  final VoidCallback onDelete;

  const _BatchFilterActions({
    required this.disabled,
    required this.onApply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: disabled ? null : onApply,
            child: const Text('Применить фильтры ко всем'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: disabled ? null : onDelete,
            child: const Text('Удалить все отфильтрованные'),
          ),
        ],
      ),
    );
  }
}

class _QuickPresetRow extends StatelessWidget {
  final String? active;
  final ValueChanged<String?> onChanged;

  const _QuickPresetRow({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final entry in TrainingSpotListState._quickFilterPresets.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: active == entry.key,
                onSelected: (selected) =>
                    onChanged(selected ? entry.key : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator();

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator> {
  bool _fadeIn = true;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _fadeIn ? 1.0 : 0.4, end: _fadeIn ? 0.4 : 1.0),
      duration: const Duration(seconds: 1),
      onEnd: () => setState(() => _fadeIn = !_fadeIn),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: const Icon(Icons.circle, size: 8, color: Colors.red),
    );
  }
}
