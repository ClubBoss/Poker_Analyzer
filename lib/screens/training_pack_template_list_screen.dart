import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../helpers/map_utils.dart';

import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/training_spot_storage_service.dart';
import '../models/training_spot_filter.dart';
import 'training_pack_template_editor_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/theme_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';

enum _SortOption { name, category, difficulty, createdAt }

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() =>
      _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState
    extends State<TrainingPackTemplateListScreen> {
  static const _prefsSortKey = 'tpl_sort_option';
  static const _prefsCollapsedKey = 'tpl_collapsed_state';
  static const _prefsFavKey = 'tpl_show_fav_only';
  static const _prefsGroupKey = 'tpl_group_by_street';
  _SortOption _sort = _SortOption.name;
  final Map<String, int?> _counts = {};
  final Map<String, bool> _collapsed = {};
  final TextEditingController _searchController = TextEditingController();
  late TrainingSpotStorageService _spotStorage;
  bool _showFavoritesOnly = false;
  bool _groupByStreet = false;
  final Set<String> _selectedIds = {};
  String _categoryFilter = 'Все';

  @override
  void initState() {
    super.initState();
    _loadSort();
    _loadCollapsed();
    _loadShowFavorites();
    _loadGroupByStreet();
  }

  Future<void> _loadSort() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsSortKey);
    if (name != null) {
      try {
        _sort = _SortOption.values.byName(name);
      } catch (_) {}
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsCollapsedKey) ?? [];
    if (list.isNotEmpty && mounted) {
      setState(() {
        for (final c in list) {
          _collapsed[c] = true;
        }
      });
    }
  }

  Future<void> _loadShowFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefsFavKey) ?? false;
    if (mounted) setState(() => _showFavoritesOnly = value);
  }

  Future<void> _loadGroupByStreet() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_prefsGroupKey) ?? false;
    if (mounted) setState(() => _groupByStreet = value);
  }

  Future<void> _setSort(_SortOption value) async {
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsSortKey, value.name);
  }

  Future<void> _setShowFavoritesOnly(bool value) async {
    setState(() => _showFavoritesOnly = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsFavKey, value);
  }

  Future<void> _setGroupByStreet(bool value) async {
    setState(() => _groupByStreet = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsGroupKey, value);
  }

  Future<void> _saveCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsCollapsedKey,
      [
        for (final e in _collapsed.entries)
          if (e.value) e.key
      ],
    );
  }

  void _cleanupCollapsed(List<String> categories) {
    final removed =
        _collapsed.keys.where((c) => !categories.contains(c)).toList();
    if (removed.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        for (final c in removed) {
          _collapsed.remove(c);
        }
      });
      _saveCollapsed();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spotStorage = context.read<TrainingSpotStorageService>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureCount(String id, Map<String, dynamic> filters) {
    if (_counts.containsKey(id)) return;
    _counts[id] = null;
    final filter = TrainingSpotFilter.fromMap(filters);
    _spotStorage.evaluateFilterCount(filter).then((value) {
      if (mounted) setState(() => _counts[id] = value);
    });
  }


  Future<void> _add() async {
    final service = context.read<TrainingPackTemplateStorageService>();
    const base = 'Новый шаблон';
    final names = service.templates.map((e) => e.name).toSet();
    var name = base;
    int i = 1;
    while (names.contains(name)) {
      i++;
      name = '$base $i';
    }
    final model = TrainingPackTemplateModel(
      id: const Uuid().v4(),
      name: name,
      description: '',
      category: '',
      filters: const {},
      createdAt: DateTime.now(),
      rating: 0,
    );
    await service.add(model);
    final result = await Navigator.push<TrainingPackTemplateModel>(
      context,
      MaterialPageRoute(
          builder: (_) => TrainingPackTemplateEditorScreen(initial: model)),
    );
    if (!mounted) return;
    if (result != null) {
      await service.update(result);
    } else {
      await service.remove(model);
    }
  }

  Future<void> _export() async {
    final service = context.read<TrainingPackTemplateStorageService>();
    try {
      final dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/training_pack_templates.json');
      await file.writeAsString(
        jsonEncode([for (final t in service.templates) t.toJson()]),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл экспортирован в Загрузки')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Ошибка экспорта')),
        );
      }
    }
  }

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final service = context.read<TrainingPackTemplateStorageService>();
    bool ok = true;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is List) {
        final list = <TrainingPackTemplateModel>[];
        for (final e in decoded) {
          if (e is Map<String, dynamic>) {
            try {
              list.add(TrainingPackTemplateModel.fromJson(e));
            } catch (_) {}
          }
        }
        service.merge(list);
        await service.saveAll();
      } else {
        ok = false;
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Шаблоны импортированы' : '⚠️ Ошибка импорта'),
      ),
    );
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.remove(id)) {
        if (_selectedIds.isEmpty) _selectedIds.clear();
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _exportSelected() async {
    if (_selectedIds.isEmpty) return;
    final service = context.read<TrainingPackTemplateStorageService>();
    final list = [
      for (final t in service.templates)
        if (_selectedIds.contains(t.id)) t.toJson()
    ];
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/selected_templates.json');
      await file.writeAsString(jsonEncode(list));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Файл экспортирован')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('⚠️ Ошибка экспорта')));
      }
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные?'),
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
    final service = context.read<TrainingPackTemplateStorageService>();
    for (final id in _selectedIds.toList()) {
      TrainingPackTemplateModel? t;
      try {
        t = service.templates.firstWhere((e) => e.id == id);
      } catch (_) {}
      if (t != null) await service.remove(t);
    }
    setState(() => _selectedIds.clear());
  }

  Future<void> _exportTemplate(TrainingPackTemplateModel t) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/pack_template_${t.id}.json');
      await file.writeAsString(jsonEncode(t.toJson()));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Файл сохранён')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('⚠️ Ошибка экспорта')));
      }
    }
  }

  Future<void> _shareTemplate(TrainingPackTemplateModel t) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pack_template_${t.id}.json');
      await file.writeAsString(jsonEncode(t.toJson()));
      await Share.shareXFiles([XFile(file.path)]);
      if (await file.exists()) await file.delete();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚠️ Не удалось поделиться')),
        );
      }
    }
  }

  Future<void> _renameTemplate(TrainingPackTemplateModel t) async {
    final service = context.read<TrainingPackTemplateStorageService>();
    final controller = TextEditingController(text: t.name);
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Переименовать шаблон'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                final exists = service.templates.any((e) =>
                    e.id != t.id &&
                    e.name.toLowerCase() == value.toLowerCase());
                if (value.isEmpty || exists) {
                  setState(() => error = value.isEmpty
                      ? 'Название обязательно'
                      : 'Уже существует');
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
    if (result != null && result != t.name) {
      final updated = t.copyWith(name: result);
      await service.update(updated);
    }
  }

  Future<void> _deleteAllTemplates() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все шаблоны?'),
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
    await context.read<TrainingPackTemplateStorageService>().clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Все шаблоны удалены')),
    );
  }

  void _toggleAll(List<String> categories) {
    final allCollapsed = categories.isNotEmpty &&
        categories.every((c) => _collapsed[c] ?? false);
    setState(() {
      for (final c in categories) {
        _collapsed[c] = !allCollapsed;
      }
    });
    _saveCollapsed();
  }

  int _compare(TrainingPackTemplateModel a, TrainingPackTemplateModel b) {
    switch (_sort) {
      case _SortOption.category:
        final r = a.category.toLowerCase().compareTo(b.category.toLowerCase());
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortOption.difficulty:
        final r = a.difficulty.compareTo(b.difficulty);
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortOption.createdAt:
        final r = b.createdAt.compareTo(a.createdAt);
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case _SortOption.name:
      default:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    }
  }

  int _compareWithFavorites(
      TrainingPackTemplateModel a, TrainingPackTemplateModel b) {
    if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
    return _compare(a, b);
  }

  Color _difficultyColor(int value) {
    switch (value) {
      case 1:
        return Colors.green.shade400;
      case 2:
        return Colors.amber.shade400;
      case 3:
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  IconData _categoryIcon(String value) {
    final v = value.toLowerCase();
    if (v.contains('spin')) return Icons.videogame_asset;
    if (v.contains('mtt') || v.contains('tournament')) {
      return Icons.emoji_events;
    }
    if (v.contains('heads') || v.contains('hu')) return Icons.sports_esports;
    return Icons.folder_open;
  }

  String _streetLabel(String? street) {
    switch (street) {
      case 'preflop':
        return 'Preflop Focus';
      case 'flop':
        return 'Flop Focus';
      case 'turn':
        return 'Turn Focus';
      case 'river':
        return 'River Focus';
      default:
        return 'Any Street';
    }
  }

  String? _targetStreet(TrainingPackTemplateModel t) {
    final streets = t.filters['streets'];
    if (streets is List && streets.length == 1 && streets.first is String) {
      final s = streets.first as String;
      if (['preflop', 'flop', 'turn', 'river'].contains(s)) return s;
    }
    return null;
  }

  Widget _statusChip(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final label = diff.inHours < 48 ? 'NEW' : 'Updated ${timeago.format(dt)}';
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TrainingPackTemplateStorageService>().templates;
    final categorySet = {
      for (final t in all)
        if (t.category.trim().isNotEmpty) t.category
    };
    final query = _searchController.text.toLowerCase();
    final templates = [
      for (final t in all)
        if ((query.isEmpty ||
                t.name.toLowerCase().contains(query) ||
                t.category.toLowerCase().contains(query)) &&
            (_groupByStreet ||
                _categoryFilter == 'Все' ||
                t.category == _categoryFilter) &&
            (!_showFavoritesOnly || t.isFavorite))
          t
    ]..sort(_compare);
    final Map<String, List<TrainingPackTemplateModel>> groups = {};
    if (_groupByStreet) {
      for (final t in templates) {
        final key = _targetStreet(t) ?? 'any';
        groups.putIfAbsent(key, () => []).add(t);
      }
    } else {
      for (final t in templates) {
        groups.putIfAbsent(t.category, () => []).add(t);
      }
    }
    for (final g in groups.values) {
      g.sort(_compareWithFavorites);
    }
    final categories = _groupByStreet
        ? [
            'preflop',
            'flop',
            'turn',
            'river',
            'any'
          ].where((k) => groups.containsKey(k)).toList()
        : (groups.keys.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())));
    _cleanupCollapsed(categories);
    final allCollapsed = categories.isNotEmpty &&
        categories.every((c) => _collapsed[c] ?? false);
    return Scaffold(
      appBar: AppBar(
        leading: _selectedIds.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedIds.clear()),
              ),
        title: _selectedIds.isEmpty
            ? const Text('Шаблоны паков')
            : Text('${_selectedIds.length} выбрано'),
        actions: _selectedIds.isEmpty
            ? [
                Builder(
                  builder: (context) {
                    final themeService = context.watch<ThemeService>();
                    return IconButton(
                      icon: Icon(themeService.mode == ThemeMode.dark
                          ? Icons.dark_mode
                          : Icons.light_mode),
                      onPressed: () {
                        themeService.toggle();
                        setState(() {});
                      },
                    );
                  },
                ),
                IconButton(
                  onPressed: () => _setShowFavoritesOnly(!_showFavoritesOnly),
                  icon: Icon(
                    _showFavoritesOnly ? Icons.star : Icons.star_border,
                    color: _showFavoritesOnly ? Colors.amber : null,
                  ),
                ),
                IconButton(
                    onPressed: _export, icon: const Icon(Icons.upload_file)),
                IconButton(
                    onPressed: _import, icon: const Icon(Icons.download)),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete_all') _deleteAllTemplates();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Text('🗑️ Удалить все шаблоны'),
                    ),
                  ],
                ),
                PopupMenuButton<_SortOption>(
                  icon: const Icon(Icons.sort),
                  padding: EdgeInsets.zero,
                  onSelected: _setSort,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: _SortOption.name, child: Text('По имени')),
                    PopupMenuItem(
                        value: _SortOption.category,
                        child: Text('По категории')),
                    PopupMenuItem(
                        value: _SortOption.difficulty,
                        child: Text('По сложности')),
                    PopupMenuItem(
                        value: _SortOption.createdAt, child: Text('По дате')),
                  ],
                ),
              ]
            : [
                IconButton(
                    onPressed: _deleteSelected, icon: const Icon(Icons.delete)),
                IconButton(
                    onPressed: _exportSelected,
                    icon: const Icon(Icons.upload_file)),
              ],
        bottom: PreferredSize(
          preferredSize:
              Size.fromHeight(kToolbarHeight * (categorySet.isEmpty ? 1 : 2)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(hintText: 'Поиск…'),
                  onChanged: (_) => setState(() {}),
                ),
                if (!_groupByStreet && categorySet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _categoryFilter,
                    dropdownColor: const Color(0xFF2A2B2E),
                    onChanged: (v) =>
                        setState(() => _categoryFilter = v ?? 'Все'),
                    items: ['Все', ...categorySet]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'toggleTplFab',
            onPressed: () => _toggleAll(categories),
            child: Icon(allCollapsed ? Icons.unfold_more : Icons.unfold_less),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addTplFab',
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'randomMistakeTplFab',
            label: const Text('Случайная ошибка'),
            onPressed: () async {
              final tpl = await TrainingPackService.createSingleRandomMistakeDrill(context);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'weakestCategoryTplFab',
            label: const Text('Слабейшая категория'),
            onPressed: () async {
              final tpl = await TrainingPackService.createDrillFromWeakestCategory(context);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
              );
            },
          ),
        ],
      ),
      body: templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SwitchListTile(
                  title: const Text('Группировать по улице'),
                  value: _groupByStreet,
                  onChanged: _setGroupByStreet,
                  activeColor: Colors.orange,
                ),
                Expanded(
                  child: (() {
                    final itemCount = categories.fold<int>(
                        0,
                        (n, c) =>
                            n +
                            (c.trim().isEmpty ? 0 : 1) +
                            (_collapsed[c] == true ? 0 : groups[c]!.length));
                    return ListView.builder(
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                  int count = 0;
                  for (final cat in categories) {
                    final list = groups[cat]!;
                    final hasHeader = cat.trim().isNotEmpty;
                    final collapsed = _collapsed[cat] ?? false;
                    if (hasHeader) {
                      if (index == count) {
                        return InkWell(
                          onTap: () {
                            setState(() => _collapsed[cat] = !collapsed);
                            _saveCollapsed();
                          },
                          child: Container(
                            color: AppColors.cardBackground,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _groupByStreet
                                        ? _streetLabel(cat == 'any' ? null : cat)
                                        : (list.isEmpty || cat.trim().isEmpty
                                            ? cat
                                            : '$cat (${list.length})'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Icon(
                                  collapsed
                                      ? Icons.expand_more
                                      : Icons.expand_less,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      count++;
                    }
                    if (!collapsed && index < count + list.length) {
                      final t = list[index - count];
                      _ensureCount(t.id, t.filters);
                      final isActive =
                          t.filters.equals(_spotStorage.activeFilters);
                      final selection = _selectedIds.isNotEmpty;
                      final selected = _selectedIds.contains(t.id);
                      final isNew = t.lastGeneratedAt != null &&
                          DateTime.now()
                                  .difference(t.lastGeneratedAt!)
                                  .inHours <
                              48;
                      final Widget tile = ListTile(
                        tileColor: isActive ? Colors.blueGrey.shade800 : null,
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selection)
                              Checkbox(
                                value: selected,
                                onChanged: (_) => _toggleSelection(t.id),
                              ),
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Icon(
                                  _categoryIcon(t.category),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Container(
                              width: 8,
                              height: 32,
                              color: _difficultyColor(t.difficulty),
                            ),
                          ],
                        ),
                        minLeadingWidth: 40,
                        onTap: selection
                            ? () => _toggleSelection(t.id)
                            : () async {
                                final model = await Navigator.push<
                                    TrainingPackTemplateModel>(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          TrainingPackTemplateEditorScreen(
                                              initial: t)),
                                );
                                if (model != null && mounted) {
                                  await context
                                      .read<
                                          TrainingPackTemplateStorageService>()
                                      .update(model);
                                }
                              },
                        onLongPress: () => _toggleSelection(t.id),
                        title: Row(
                          children: [
                            Expanded(child: Text(t.name)),
                            if (isNew)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Chip(
                                  label: Text('NEW',
                                      style: TextStyle(fontSize: 12)),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.bar_chart, size: 20),
                              onPressed: () {
                                final total = t.spots.length;
                                final pct = total == 0
                                    ? 0
                                    : (t.evCovered * 100 / total).round();
                                final text =
                                    'EV calculated for $pct% of spots';
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text(text)));
                              },
                            ),
                            IconButton(
                              icon: Icon(t.isFavorite
                                  ? Icons.star
                                  : Icons.star_border),
                              color:
                                  t.isFavorite ? Colors.amber : Colors.white54,
                              onPressed: () {
                                final updated =
                                    t.copyWith(isFavorite: !t.isFavorite);
                                context
                                    .read<TrainingPackTemplateStorageService>()
                                    .update(updated);
                              },
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (_counts[t.id] == null
                                      ? 'Невозможно оценить'
                                      : '≈ ${_counts[t.id]} рук') +
                                  (isActive ? ' (активен)' : ''),
                            ),
                            if (t.lastGeneratedAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _statusChip(t.lastGeneratedAt!),
                              ),
                          ],
                        ),
                        trailing: selection
                            ? null
                            : PopupMenuButton<String>(
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'apply':
                                      _spotStorage.activeFilters
                                        ..clear()
                                        ..addAll(t.filters);
                                      _spotStorage.notifyListeners();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Шаблон применён')));
                                      break;
                                    case 'export':
                                      if (!t.isDraft) await _exportTemplate(t);
                                      break;
                                    case 'share':
                                      if (!t.isDraft) await _shareTemplate(t);
                                      break;
                                    case 'rename':
                                      await _renameTemplate(t);
                                      break;
                                    case 'duplicate':
                                      final copy = t.copyWith(
                                        id: const Uuid().v4(),
                                        name: 'Копия ${t.name}',
                                      );
                                      await context
                                          .read<
                                              TrainingPackTemplateStorageService>()
                                          .add(copy);
                                      break;
                                  }
                                },
                                itemBuilder: (_) {
                                  final items = <PopupMenuEntry<String>>[
                                    const PopupMenuItem(
                                        value: 'apply',
                                        child: Text('Применить шаблон')),
                                  ];
                                  if (!t.isDraft) {
                                    items.addAll(const [
                                      PopupMenuItem(
                                          value: 'export',
                                          child: Text('📤 Экспортировать')),
                                      PopupMenuItem(
                                          value: 'share',
                                          child: Text('📤 Поделиться')),
                                    ]);
                                  }
                                  items.addAll(const [
                                    PopupMenuItem(
                                        value: 'rename',
                                        child: Text('✏️ Переименовать')),
                                    PopupMenuItem(
                                        value: 'duplicate',
                                        child: Text('📄 Дублировать')),
                                  ]);
                                  return items;
                                },
                              ),
                      );
                      return selection
                          ? tile
                          : Dismissible(
                              key: ValueKey(t.id),
                              confirmDismiss: (_) async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Удалить шаблон?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Отмена'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Удалить'),
                                      ),
                                    ],
                                  ),
                                );
                                return ok == true;
                              },
                              onDismissed: (_) => context
                                  .read<TrainingPackTemplateStorageService>()
                                  .remove(t),
                              child: tile,
                            );
                    }
                    if (!collapsed) count += list.length;
                  }
                  return const SizedBox.shrink();
                },
              );
                })(),
              ],
            ),
    );
  }
}
