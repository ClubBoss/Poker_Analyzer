import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/training_pack_storage_service.dart';
import '../helpers/date_utils.dart';
import '../models/training_pack.dart';
import '../theme/app_colors.dart';
import 'training_pack_screen.dart';
import 'pack_editor_screen.dart';
import '../widgets/difficulty_chip.dart';
import '../widgets/info_tooltip.dart';
import '../helpers/color_utils.dart';
import "../widgets/progress_chip.dart";
import '../widgets/color_picker_dialog.dart';
import 'package:intl/intl.dart';
import '../services/tag_service.dart';
import 'training_pack_template_list_screen.dart';

class MyTrainingPacksScreen extends StatefulWidget {
  const MyTrainingPacksScreen({super.key});

  @override
  State<MyTrainingPacksScreen> createState() => _MyTrainingPacksScreenState();
}

class _MyTrainingPacksScreenState extends State<MyTrainingPacksScreen> {
  static const _groupKey = 'group_by_color';
  static const _lastColorKey = 'pack_last_color';
  static const _sortKey = 'pack_sort_option';
  static const _searchKey = 'pack_search_query';
  static const _tagKey = 'pack_tag_filter';
  final Map<String, DateTime?> _dates = {};
  final TextEditingController _searchController = TextEditingController();
  String _sort = 'name';
  int _diffFilter = 0;
  String _colorFilter = 'All';
  String _tagFilter = 'All';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _prefs = prefs;
      _diffFilter = prefs.getInt('pack_diff_filter') ?? 0;
      _colorFilter = prefs.getString('pack_color_filter') ?? 'All';
      _sort = prefs.getString(_sortKey) ?? 'name';
      _searchController.text = prefs.getString(_searchKey) ?? '';
      _tagFilter = prefs.getString(_tagKey) ?? 'All';
      _groupByColor = prefs.getBool(_groupKey) ?? false;
      _lastColor = colorFromHex(prefs.getString(_lastColorKey) ?? '#2196F3');
    });
    if (_searchController.text.isNotEmpty) {
      await _setSearch(_searchController.text);
    }
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

  Future<void> _resetFilters() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, 'name');
    await prefs.remove('pack_diff_filter');
    await prefs.remove('pack_color_filter');
    await prefs.remove(_searchKey);
    await prefs.remove(_tagKey);
    await prefs.setBool(_groupKey, false);
    setState(() {
      _sort = 'name';
      _diffFilter = 0;
      _colorFilter = 'All';
      _tagFilter = 'All';
      _groupByColor = false;
      _searchController.clear();
    });
  }

  Future<void> _setSort(String value) async {
    setState(() => _sort = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, value);
  }

  Future<void> _setSearch(String value) async {
    setState(() {});
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_searchKey, value);
  }

  Future<void> _setTagFilter(String value) async {
    setState(() => _tagFilter = value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (value == 'All') {
      await prefs.remove(_tagKey);
    } else {
      await prefs.setString(_tagKey, value);
    }
  }

  Future<void> _showPackMenu(TrainingPack pack) async {
    if (pack.isBuiltIn || pack.history.isEmpty) return;
    final reset = await showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(pack.name),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Сбросить прогресс'),
          ),
        ],
      ),
    );
    if (reset == true) {
      await context.read<TrainingPackStorageService>().clearProgress(pack);
      if (mounted) {
        await _loadDates();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Прогресс сброшен')),
        );
      }
    }
  }

  Future<void> _importPack() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final msg = await context.read<TrainingPackStorageService>().importPack(bytes);
    if (!mounted) return;
    if (msg == null) {
      await _loadDates();
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Пак импортирован')));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('⚠ $msg')));
    }
  }

  Future<void> _duplicatePack(TrainingPack pack) async {
    final copy = await context.read<TrainingPackStorageService>().duplicatePack(pack);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PackEditorScreen(pack: copy)),
    );
    if (mounted) {
      await _loadDates();
      setState(() {});
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Копия пакa создана')));
    }
  }

  Future<void> _deletePack(TrainingPack pack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить пак "${pack.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Да'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final result = await context.read<TrainingPackStorageService>().removePack(pack);
      if (result != null && mounted) {
        _showUndoDelete(result.$1, result.$2);
      }
    }
  }

  void _showUndoDelete(TrainingPack pack, int index) {
    final snack = SnackBar(
      content: const Text('Пак удалён'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => context.read<TrainingPackStorageService>().restorePack(pack, index),
      ),
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
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
      case 'category':
        return a.category.compareTo(b.category);
      case 'lastAttempt':
        final da = a.lastAttemptDate;
        final db = b.lastAttemptDate;
        if (da.isAtSameMomentAs(db)) return a.name.compareTo(b.name);
        return db.compareTo(da);
      default:
        return a.name.compareTo(b.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final packs = context.watch<TrainingPackStorageService>().packs.where((p) => !p.isBuiltIn).toList();
    final allTags = {for (final p in packs) ...p.tags};
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
    if (_tagFilter != 'All') {
      packs.retainWhere((p) => p.tags.contains(_tagFilter));
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      packs.retainWhere((p) =>
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query));
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'importPackFab',
            onPressed: _importPack,
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'createFromTplFab',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TrainingPackTemplateListScreen()),
              );
            },
            label: const Text('Из шаблона'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск'),
              onChanged: (v) => _setSearch(v),
            ),
          ),
          Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButton<String>(
            value: _sort,
            underline: const SizedBox.shrink(),
            onChanged: (v) => _setSort(v ?? 'name'),
            items: const [
              DropdownMenuItem(value: 'name', child: Text('По имени')),
              DropdownMenuItem(value: 'lastAttempt', child: Text('Последняя попытка')),
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
        if (allTags.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final t in allTags)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _tagFilter == t,
                      selectedColor:
                          colorFromHex(context.read<TagService>().colorOf(t)),
                      onSelected: (_) =>
                          _setTagFilter(_tagFilter == t ? 'All' : t),
                    ),
                  ),
                if (_tagFilter != 'All')
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.white70,
                    tooltip: 'Очистить',
                    onPressed: () => _setTagFilter('All'),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetFilters,
              child: const Text('Сбросить фильтры'),
            ),
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
                    final pct = p.pctComplete;
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
                      onLongPress: () {
                        if (_selectionMode) {
                          _toggleSelect(p);
                        } else if (p.history.isNotEmpty) {
                          _showPackMenu(p);
                        } else {
                          _toggleSelect(p);
                        }
                      },
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
                          const SizedBox(width: 4),
                          InfoTooltip(
                            message: pct == 1
                                ? 'Completed!'
                                : 'Solved ${p.solved} of ${p.hands.length} hands',
                            child: ProgressChip(pct),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.lastAttempted > 0)
                            Row(
                              children: [
                                Text('Решено: ${p.solved} / ${p.lastAttempted}'),
                                const SizedBox(width: 12),
                                Text('Последняя попытка: '
                                    '${DateFormat('dd.MM.yy').format(p.lastAttemptDate)}'),
                              ],
                            ),
                          Text('${p.category} • ${p.spots.isNotEmpty ? '${p.spots.length} spots' : '${p.hands.length} hands'}'),
                          if (p.tags.isNotEmpty) Text(p.tags.join(', ')),
                        ],
                      ),
                      trailing: _selectionMode
                          ? Checkbox(
                              value: _selected.contains(p),
                              onChanged: (_) => _toggleSelect(p),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!p.isBuiltIn)
                                  IconButton(
                                    icon: const Icon(Icons.build, size: 18),
                                    onPressed: () async {
                                      final saved = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              PackEditorScreen(pack: p),
                                        ),
                                      );
                                      if (saved == true && mounted) {
                                        await _loadDates();
                                        setState(() {});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Пак сохранён')),
                                        );
                                      }
                                    },
                                  ),
                                Text(date != null ? formatDate(date) : '-'),
                                if (!p.isBuiltIn)
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    onSelected: (v) async {
                                      if (v == 'export') {
                                        final file = await context
                                            .read<TrainingPackStorageService>()
                                            .exportPack(p);
                                        if (!mounted) return;
                                        if (file != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                                content: Text('Файл сохранён в Загрузках')),
                                          );
                                        }
                                      } else if (v == 'duplicate') {
                                        await _duplicatePack(p);
                                      } else if (v == 'delete') {
                                        await _deletePack(p);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'export',
                                        child: Row(
                                          children: [
                                            Icon(Icons.upload_file),
                                            SizedBox(width: 8),
                                            Text('Экспорт JSON'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'duplicate',
                                        child: Row(
                                          children: [
                                            Icon(Icons.copy),
                                            SizedBox(width: 8),
                                            Text('Дублировать'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete),
                                            SizedBox(width: 8),
                                            Text('Удалить'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
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
