import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../asset_manifest.dart';

import '../helpers/color_utils.dart';
import '../services/template_storage_service.dart';
import '../models/training_pack_template.dart';
import '../services/training_session_service.dart';
import 'training_session_screen.dart';
import 'create_pack_from_template_screen.dart';
import 'create_template_screen.dart';
import 'template_hands_editor_screen.dart';
import 'template_preview_dialog.dart';
import '../widgets/sync_status_widget.dart';
import 'session_history_screen.dart';
import 'v2/training_pack_template_editor_screen.dart';
import '../repositories/training_pack_preset_repository.dart';
import '../models/v2/training_pack_preset.dart';
import '../services/training_pack_template_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/bulk_evaluator_service.dart';
import '../utils/template_coverage_utils.dart';
import '../services/mistake_review_pack_service.dart';
import 'package:intl/intl.dart';
import 'training_stats_screen.dart';
import '../helpers/category_translations.dart';

class TemplateLibraryScreen extends StatefulWidget {
  const TemplateLibraryScreen({super.key});

  @override
  State<TemplateLibraryScreen> createState() => _TemplateLibraryScreenState();
}

class _TemplateLibraryScreenState extends State<TemplateLibraryScreen> {
  static const _key = 'lib_game_type';
  static const _sortKey = 'lib_sort';
  static const _favKey = 'fav_tpl_ids';
  static const _needsPracticeKey = 'lib_needs_practice';
  static const _favOnlyKey = 'lib_fav_only';
  static const _selTagKey = 'lib_sel_tag';
  static const kStarterTag = 'starter';
  static const kFeaturedTag = 'featured';
  static final _manifestFuture = AssetManifest.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'all';
  String _sort = 'edited';
  bool _needsPractice = false;
  bool _loadingNeedsPractice = false;
  final Set<String> _needsPracticeIds = {};
  final Set<String> _favorites = {};
  bool _favoritesOnly = false;
  String? _selectedTag;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _init();
  }

  Future<void> _init() async {
    final prefs = await _load();
    await _autoImport(prefs);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<SharedPreferences> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _filter = prefs.getString(_key) ?? 'all';
      _sort = prefs.getString(_sortKey) ?? 'edited';
      _favorites
        ..clear()
        ..addAll(prefs.getStringList(_favKey) ?? []);
      _needsPractice = prefs.getBool(_needsPracticeKey) ?? false;
      _favoritesOnly = prefs.getBool(_favOnlyKey) ?? false;
      _selectedTag = prefs.getString(_selTagKey);
    });
    final cloud = context.read<CloudSyncService>();
    final remoteRaw = await cloud.load(_favKey);
    List<String> remote = [];
    try {
      if (remoteRaw != null) remote = List<String>.from(jsonDecode(remoteRaw));
    } catch (_) {}
    final before = {..._favorites};
    _favorites.addAll(remote);
    final merged = _favorites.toList()..sort();
    if (!setEquals(before, _favorites)) {
      await prefs.setStringList(_favKey, merged);
    }
    if (!setEquals(remote.toSet(), _favorites)) {
      unawaited(
          cloud.save(_favKey, jsonEncode(merged)).catchError((_) {}));
    }
    if (_needsPractice) _updateNeedsPractice(true);
    return prefs;
  }

  Future<void> _setFilter(String value) async {
    setState(() => _filter = value);
    final prefs = await SharedPreferences.getInstance();
    if (value == 'all') {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, value);
    }
  }

  Future<void> _setSort(String value) async {
    setState(() => _sort = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortKey, value);
  }

  Future<void> _updateNeedsPractice(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_needsPracticeKey, value);
    setState(() {
      _needsPractice = value;
      if (!value) _needsPracticeIds.clear();
    });
    if (!value) return;
    setState(() => _loadingNeedsPractice = true);
    final templates = context.read<TemplateStorageService>().templates;
    final ids = <String>{};
    for (final t in templates) {
      final acc =
          (await TrainingPackStatsService.getStats(t.id))?.accuracy ?? 1.0;
      if (acc < .8) ids.add(t.id);
    }
    if (!mounted) return;
    setState(() {
      _needsPracticeIds
        ..clear()
        ..addAll(ids);
      _loadingNeedsPractice = false;
    });
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (!_favorites.add(id)) {
        _favorites.remove(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    final list = _favorites.toList()..sort();
    await prefs.setStringList(_favKey, list);
    unawaited(context
        .read<CloudSyncService>()
        .save(_favKey, jsonEncode(list))
        .catchError((_) {}));
  }

  Future<void> _setFavoritesOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_favOnlyKey, value);
    setState(() => _favoritesOnly = value);
  }

  Future<void> _setSelectedTag(String? tag) async {
    final prefs = await SharedPreferences.getInstance();
    if (tag == null) {
      await prefs.remove(_selTagKey);
    } else {
      await prefs.setString(_selTagKey, tag);
    }
    setState(() => _selectedTag = tag);
  }

  List<TrainingPackTemplate> _applySorting(List<TrainingPackTemplate> list) {
    final copy = [...list];
    switch (_sort) {
      case 'name':
        copy.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'spots':
        copy.sort((a, b) {
          final cmp = b.hands.length.compareTo(a.hands.length);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      default:
        copy.sort((a, b) {
          final cmp = b.updatedAt.compareTo(a.updatedAt);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
    }
    return copy;
  }

  bool _hasTag(TrainingPackTemplate t, String tag) =>
      t.tags.any((x) => x.toLowerCase() == tag);

  bool _isStarter(TrainingPackTemplate t) => _hasTag(t, kStarterTag);

  bool _isFeatured(TrainingPackTemplate t) => _hasTag(t, kFeaturedTag);

  List<TrainingPackTemplate> _applyFilters(
      List<TrainingPackTemplate> templates) {
    var visible = templates;
    if (_filter == 'tournament') {
      visible = [
        for (final t in visible)
          if (t.gameType.toLowerCase().startsWith('tour')) t
      ];
    } else if (_filter == 'cash') {
      visible = [
        for (final t in visible)
          if (t.gameType.toLowerCase().contains('cash')) t
      ];
    }
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      visible = [
        for (final t in visible)
          if (t.name.toLowerCase().contains(query) ||
              t.tags.any((tag) => tag.toLowerCase().contains(query)))
            t
      ];
    }
    if (_needsPractice) {
      visible = [
        for (final t in visible)
          if (_needsPracticeIds.contains(t.id)) t
      ];
    }
    if (_favoritesOnly) {
      visible = [for (final t in visible) if (_favorites.contains(t.id)) t];
    }
    if (_selectedTag != null) {
      visible = [for (final t in visible) if (t.tags.contains(_selectedTag)) t];
    }
    return visible;
  }

  Future<void> _importTemplate() async {
    if (_importing) return;
    _importing = true;
    if (mounted) setState(() {});
    String? path;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      Uint8List? data = result.files.single.bytes;
      path = result.files.single.path;
      data ??= path != null ? await File(path).readAsBytes() : null;
      if (data == null) throw 'Пустой файл';

      final service = context.read<TemplateStorageService>();
      final error = service.importTemplate(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Шаблон импортирован')),
      );
    } catch (e) {
      debugPrint('🛑 Импорт не удался${path != null ? ' ($path)' : ''}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось импортировать пак')),
        );
      }
    } finally {
      _importing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _createTemplate() async {
    final template = await Navigator.push<TrainingPackTemplate?>(
      context,
      MaterialPageRoute(builder: (_) => const CreateTemplateScreen()),
    );
    if (template == null) return;
    context.read<TemplateStorageService>().addTemplate(template);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateHandsEditorScreen(template: template),
      ),
    );
  }

  Future<void> _generateFromPreset() async {
    final presets = await TrainingPackPresetRepository.getAll();
    if (!mounted) return;
    final preset = await showModalBottomSheet<TrainingPackPreset>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final p in presets)
              ListTile(
                title: Text(p.name),
                subtitle: Text(p.description),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (preset == null) return;
    final tpl = await TrainingPackTemplateService.generateFromPreset(preset);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: tpl,
          templates: context.read<TemplateStorageService>().templates,
        ),
      ),
    );
  }

  Future<void> _importStarterPacks() async {
    final presets = await TrainingPackPresetRepository.getAll();
    if (!mounted) return;
    final service = context.read<TemplateStorageService>();
    var added = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setState) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (final p in presets) {
                  final exists = service.templates
                      .any((t) => t.id == p.id || t.name == p.name);
                  if (exists) continue;
                  final tpl =
                      await TrainingPackTemplateService.generateFromPreset(p);
                  tpl.isBuiltIn = true;
                  await BulkEvaluatorService().generateMissing(tpl);
                  TemplateCoverageUtils.recountAll(tpl);
                  service.addTemplate(tpl);
                  added++;
                }
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return const AlertDialog(
              content: LinearProgressIndicator(),
            );
          },
        );
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added $added packs')));
  }

  Future<void> _autoImport([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    if (_importing) return;
    if (prefs.getBool('imported_initial_templates') == true) return;
    final list = context.read<TemplateStorageService>().templates;
    if (list.isEmpty) {
      await _importInitialTemplates(prefs);
      if (mounted) setState(() {});
    }
  }

  Future<void> _importInitialTemplates([SharedPreferences? prefs]) async {
    if (_importing) return;
    _importing = true;
    FocusScope.of(context).unfocus();
    setState(() {});
    prefs ??= await SharedPreferences.getInstance();
    if (prefs.getBool('imported_initial_templates') == true) {
      setState(() => _importing = false);
      return;
    }
    final manifest = await _manifestFuture;
    final paths = manifest.keys.where(
        (e) => e.startsWith('assets/templates/initial/') && e.endsWith('.json'));
    final service = context.read<TemplateStorageService>();
    var added = 0;
    for (final p in paths) {
      try {
        final data = jsonDecode(await rootBundle.loadString(p));
        if (data is Map<String, dynamic>) {
          final tpl = TrainingPackTemplate.fromJson(
              Map<String, dynamic>.from(data))
            ..isBuiltIn = true;
          if (service.templates.every((t) => t.id != tpl.id)) {
            service.addTemplate(tpl);
            added++;
          } else {
            debugPrint('⚠️  Skip ${tpl.name}: duplicate id');
          }
        }
      } catch (e) {
        debugPrint('Импорт не удался для $p: $e');
      }
    }
    await prefs.setBool('imported_initial_templates', true);
    unawaited(
        context.read<CloudSyncService>().save('imported_initial_templates', '1'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      if (added == 0) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Не удалось импортировать некоторые паки')));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(Intl.plural(added,
                zero: 'Паки не импортированы',
                one: 'Добавлён $added пак',
                few: 'Добавлено $added пака',
                many: 'Добавлено $added паков'))));
      }
    });
    setState(() => _importing = false);
  }

  Future<TrainingPackTemplate?> _loadLastPack(BuildContext context) async {
    final service = context.read<TemplateStorageService>();
    final list = [for (final t in service.templates) if (!t.isBuiltIn) t];
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list.isNotEmpty ? list.first : null;
  }

  Future<void> _quickPractice() async {
    final templates = context.read<TemplateStorageService>().templates;
    TrainingPackTemplate? tpl;
    if (_needsPracticeIds.isNotEmpty) {
      tpl = templates.firstWhere(
        (t) => _needsPracticeIds.contains(t.id),
        orElse: () => TrainingPackTemplate(id: '', name: ''),
      );
      if (tpl.id.isEmpty) tpl = null;
    }
    tpl ??= (
      () {
        final builtIn = [for (final t in templates) if (t.isBuiltIn) t];
        if (builtIn.isEmpty) return null;
        return builtIn[Random().nextInt(builtIn.length)];
      }()
    );
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Widget _item(TrainingPackTemplate t) {
    final parts = t.version.split('.');
    final version = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : t.version;
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorFromHex(t.defaultColor)),
        title: Row(
          children: [
            if (t.isBuiltIn) ...[
              const Icon(Icons.shield, size: 18, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  t.name,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ] else ...[
              Expanded(child: Text(t.name)),
            ],
          ],
        ),
        subtitle: FutureBuilder<TrainingPackStat?>(
          future: TrainingPackStatsService.getStats(t.id),
          builder: (context, snap) {
            final c = translateCategory(t.category);
            final main = '${c.isEmpty ? 'Без категории' : c} • ${t.hands.length} рук • v$version';
            final stat = snap.data;
            if (stat == null) return Text(main);
            final date = DateFormat('dd MMM', Intl.getCurrentLocale()).format(stat.last);
            final color = stat.accuracy >= 1
                ? Colors.green
                : stat.accuracy >= .5
                    ? Colors.amber
                    : Colors.red;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(main),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: stat.accuracy,
                  backgroundColor: Colors.white12,
                  color: color,
                  minHeight: 4,
                ),
                const SizedBox(height: 2),
                Text('Last trained: $date',
                    style: const TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            );
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _favorites.contains(t.id) ? Icons.star : Icons.star_border,
              ),
              color: _favorites.contains(t.id) ? Colors.amber : Colors.white54,
              onPressed: () => _toggleFavorite(t.id),
            ),
            TextButton(
              onPressed: () {
                context.read<TrainingSessionService>().startSession(t);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
                );
              },
              child: const Text('▶️ Train'),
            ),
          ],
        ),
        onTap: () async {
          final create = await showDialog<bool>(
            context: context,
            builder: (_) => TemplatePreviewDialog(template: t),
          );
          if (create == true && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreatePackFromTemplateScreen(template: t)),
            );
          }
        },
      ),
    );
  }

  Widget get _emptyTile => const ListTile(
        title: Center(
          child: Text(
            'Нет подходящих паков',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final templates = context.watch<TemplateStorageService>().templates;
    final tagList = <String>{for (final t in templates) ...t.tags}.toList()..sort();
    final visible = _applyFilters(templates);
    final sortedVisible = _applySorting(visible);
    final query = _searchCtrl.text.trim().toLowerCase();
    final hasResults = sortedVisible.isNotEmpty;
    final filteringActive =
        query.isNotEmpty || _filter != 'all' || _needsPractice || _favoritesOnly || _selectedTag != null;
    final fav = <TrainingPackTemplate>[];
    final nonFav = <TrainingPackTemplate>[];
    for (final t in sortedVisible) {
      (_favorites.contains(t.id) ? fav : nonFav).add(t);
    }
    final sortedFav = _applySorting(fav);
    final featured =
        _applySorting([for (final t in nonFav) if (_isFeatured(t)) t]);
    final remaining = [for (final t in nonFav) if (!_isFeatured(t)) t];
    final builtInStarter = _applySorting([
      for (final t in remaining)
        if (t.isBuiltIn && _isStarter(t)) t
    ]);
    final builtInOther = _applySorting([
      for (final t in remaining)
        if (t.isBuiltIn && !_isStarter(t)) t
    ]);
    final user =
        _applySorting([for (final t in remaining) if (!t.isBuiltIn) t]);
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(hintText: 'Поиск', border: InputBorder.none),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _filter,
              underline: const SizedBox.shrink(),
              onChanged: (v) => v != null ? _setFilter(v) : null,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All')),
                DropdownMenuItem(value: 'tournament', child: Text('Tournament')),
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Text('📊', style: TextStyle(fontSize: 20)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TrainingStatsScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _setSort,
            initialValue: _sort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Name')),
              PopupMenuItem(value: 'spots', child: Text('Spots')),
              PopupMenuItem(value: 'edited', child: Text('Edited')),
            ],
          ),
          SyncStatusIcon.of(context),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<TrainingPackTemplate?>(
            future: _loadLastPack(context),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final t = snap.data!;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackTemplateEditorScreen(
                          template: t,
                          templates: context
                              .read<TemplateStorageService>()
                              .templates,
                        ),
                      ),
                    );
                  },
                  child: Text('Continue: ${t.name}'),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _importStarterPacks,
              child: const Text('Import Starter Packs'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _importInitialTemplates,
              child: const Text('Импортировать базовые паки'),
            ),
          ),
          Builder(
            builder: (context) {
              final service = context.watch<MistakeReviewPackService>();
              if (!service.hasMistakes()) return const SizedBox.shrink();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.error, color: Colors.orangeAccent),
                    title: const Text('Review Mistakes'),
                    onTap: () async {
                      final tpl = await service.buildPack(context);
                      if (tpl == null) return;
                      await context
                          .read<TrainingSessionService>()
                          .startSession(tpl, persist: false);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TrainingSessionScreen()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Needs Practice'),
                selected: _needsPractice,
                onSelected: (v) => _updateNeedsPractice(v),
              ),
              FilterChip(
                label: const Text('Favorites'),
                selected: _favoritesOnly,
                onSelected: (v) => _setFavoritesOnly(v),
              ),
            ],
          ),
        ),
        if (tagList.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final tag in tagList)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag),
                      selected: _selectedTag == tag,
                      onSelected: (_) {
                        if (_selectedTag == tag) {
                          _setSelectedTag(null);
                        } else {
                          _setSelectedTag(tag);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        if (_loadingNeedsPractice) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: hasResults
              ? ListView(
                  children: [
                    if (featured.isNotEmpty) ...[
                      const ListTile(title: Text('Рекомендуемые паки')),
                      for (final t in featured) _item(t),
                      if (sortedFav.isNotEmpty ||
                          builtInStarter.isNotEmpty ||
                          builtInOther.isNotEmpty ||
                          user.isNotEmpty)
                        const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (sortedFav.isNotEmpty ||
                          builtInStarter.isNotEmpty ||
                          builtInOther.isNotEmpty ||
                          user.isNotEmpty)
                        const Divider(),
                    ],
                    if (sortedFav.isNotEmpty) ...[
                      const ListTile(title: Text('★ Favorites')),
                      for (final t in sortedFav) _item(t),
                      if (builtInStarter.isNotEmpty || builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (builtInStarter.isNotEmpty || builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ],
                    if (builtInStarter.isNotEmpty) ...[
                      const ListTile(title: Text('Стартовые паки')),
                      for (final t in builtInStarter) _item(t),
                      if (builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ],
                    if (builtInOther.isNotEmpty) ...[
                      const ListTile(title: Text('Встроенные паки')),
                      for (final t in builtInOther) _item(t),
                      if (user.isNotEmpty) const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (user.isNotEmpty) const Divider(),
                    ],
                    if (user.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child:
                            Text('Your Packs', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.add),
                            title: const Text('Создать новый пак'),
                            onTap: _createTemplate,
                          ),
                        ),
                      ),
                      for (final t in user) _item(t),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                    ],
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 96, color: Colors.white30),
                      const SizedBox(height: 24),
                      const Text('Нет доступных паков'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _importStarterPacks,
                        child: const Text('Импортировать паки'),
                      ),
                    ],
                  ),
                ),
        ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'quickPracticeFab',
            onPressed: _quickPractice,
            label: const Text('Quick Practice'),
            icon: const Icon(Icons.play_arrow),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'genFromPresetFab',
            onPressed: _generateFromPreset,
            label: const Text('Generate from Preset'),
            icon: const Icon(Icons.auto_awesome),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'importTemplateFab',
            onPressed: _importTemplate,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'createTemplateFab',
            onPressed: _createTemplate,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        scaffold,
        AnimatedOpacity(
          opacity: _importing ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const _ImportOverlay(),
        ),
      ],
    );
  }
}

class _ImportOverlay extends StatelessWidget {
  const _ImportOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        ModalBarrier(color: Colors.black38, dismissible: false),
        Center(
          child: Semantics(
            label: 'Импорт паков…',
            child: CircularProgressIndicator(),
          ),
        ),
      ],
    );
  }
}
