import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';

import '../models/training_pack_template_model.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/training_spot_storage_service.dart';
import 'training_pack_template_editor_screen.dart';
import 'package:uuid/uuid.dart';

enum _SortOption { name, category, difficulty, createdAt }

class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() => _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState
    extends State<TrainingPackTemplateListScreen> {
  static const _prefsSortKey = 'tpl_sort_option';
  static const _prefsCollapsedKey = 'tpl_collapsed_state';
  _SortOption _sort = _SortOption.name;
  final Map<String, int?> _counts = {};
  final Map<String, bool> _collapsed = {};
  final TextEditingController _searchController = TextEditingController();
  late TrainingSpotStorageService _spotStorage;

  @override
  void initState() {
    super.initState();
    _loadSort();
    _loadCollapsed();
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

  Future<void> _setSort(_SortOption value) async {
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsSortKey, value.name);
  }

  Future<void> _saveCollapsed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsCollapsedKey,
      [for (final e in _collapsed.entries) if (e.value) e.key],
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
    _spotStorage.evaluateFilterCount(filters).then((value) {
      if (mounted) setState(() => _counts[id] = value);
    });
  }
  Future<void> _add() async {
    final model = await Navigator.push<TrainingPackTemplateModel>(
      context,
      MaterialPageRoute(builder: (_) => const TrainingPackTemplateEditorScreen()),
    );
    if (model != null && mounted) {
      await context.read<TrainingPackTemplateStorageService>().add(model);
    }
  }

  Future<void> _export() async {
    final service = context.read<TrainingPackTemplateStorageService>();
    try {
      final dir =
          await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
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
    final controller = TextEditingController(text: t.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать шаблон'),
        content: TextField(
          controller: controller,
          autofocus: true,
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
      ),
    );
    if (result != null && result.isNotEmpty && result != t.name) {
      final updated = t.copyWith(name: result);
      await context.read<TrainingPackTemplateStorageService>().update(updated);
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
    if (v.contains('mtt') || v.contains('tournament')) return Icons.emoji_events;
    if (v.contains('heads') || v.contains('hu')) return Icons.sports_esports;
    return Icons.folder_open;
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<TrainingPackTemplateStorageService>().templates;
    final query = _searchController.text.toLowerCase();
    final templates = [
      for (final t in all)
        if (query.isEmpty ||
            t.name.toLowerCase().contains(query) ||
            t.category.toLowerCase().contains(query))
          t
    ]..sort(_compare);
    final Map<String, List<TrainingPackTemplateModel>> groups = {};
    for (final t in templates) {
      groups.putIfAbsent(t.category, () => []).add(t);
    }
    for (final g in groups.values) {
      g.sort(_compare);
    }
    final categories = groups.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    _cleanupCollapsed(categories);
    final allCollapsed =
        categories.isNotEmpty && categories.every((c) => _collapsed[c] ?? false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаблоны паков'),
        actions: [
          IconButton(onPressed: _export, icon: const Icon(Icons.upload_file)),
          IconButton(onPressed: _import, icon: const Icon(Icons.download)),
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
              PopupMenuItem(value: _SortOption.name, child: Text('По имени')),
              PopupMenuItem(value: _SortOption.category, child: Text('По категории')),
              PopupMenuItem(value: _SortOption.difficulty, child: Text('По сложности')),
              PopupMenuItem(value: _SortOption.createdAt, child: Text('По дате')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(hintText: 'Поиск…'),
              onChanged: (_) => setState(() {}),
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
        ],
      ),
      body: templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : (() {
              final itemCount = categories.fold<int>(
                  0,
                  (n, c) =>
                      n + (c.trim().isEmpty ? 0 : 1) + (_collapsed[c] == true ? 0 : groups[c]!.length));
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
                                    list.isEmpty || cat.trim().isEmpty
                                        ? cat
                                        : '$cat (${list.length})',
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
                      return Dismissible(
                        key: ValueKey(t.id),
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Удалить шаблон?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Отмена'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          return ok == true;
                        },
                        onDismissed: (_) =>
                            context.read<TrainingPackTemplateStorageService>().
                                remove(t),
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                          onTap: () async {
                            final model = await Navigator.push<
                                TrainingPackTemplateModel>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      TrainingPackTemplateEditorScreen(initial: t)),
                            );
                            if (model != null && mounted) {
                              await context
                                  .read<TrainingPackTemplateStorageService>()
                                  .update(model);
                            }
                          },
                          title: Text(t.name),
                          subtitle: Text(
                            _counts[t.id] == null
                                ? 'Невозможно оценить'
                                : '≈ ${_counts[t.id]} рук',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'apply':
                                  _spotStorage.activeFilters
                                    ..clear()
                                    ..addAll(t.filters);
                                  _spotStorage.notifyListeners();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Шаблон применён')));
                                  break;
                                case 'export':
                                  await _exportTemplate(t);
                                  break;
                                case 'share':
                                  await _shareTemplate(t);
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
                                      .read<TrainingPackTemplateStorageService>()
                                      .add(copy);
                                  break;
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'apply', child: Text('Применить шаблон')),
                              PopupMenuItem(
                                  value: 'export',
                                  child: Text('📤 Экспортировать')),
                              PopupMenuItem(
                                  value: 'share', child: Text('📤 Поделиться')),
                              PopupMenuItem(
                                  value: 'rename', child: Text('✏️ Переименовать')),
                              PopupMenuItem(
                                  value: 'duplicate', child: Text('📄 Дублировать')),
                            ],
                          ),
                        ),
                      );
                    }
                    if (!collapsed) count += list.length;
                  }
                  return const SizedBox.shrink();
                },
              );
            })(),
    );
  }
}
