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
import '../theme/app_colors.dart';

import '../helpers/color_utils.dart';
import '../services/template_storage_service.dart';
import '../models/training_pack_template.dart';
import '../models/training_pack_template_model.dart';
import '../models/v2/training_pack_template.dart' as v2;
import '../utils/template_difficulty.dart';
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
import '../services/training_pack_service.dart';
import 'mistake_review_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_log.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_template_storage_service.dart';
import 'package:intl/intl.dart';
import 'training_stats_screen.dart';
import '../helpers/category_translations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/user_action_logger.dart';

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
  static const _recentOnlyKey = 'lib_recent_only';
  static const _inProgressKey = 'lib_in_progress';
  static const _hideCompletedKey = 'lib_hide_completed';
  static const _selTagKey = 'lib_sel_tag';
  static const kStarterTag = 'starter';
  static const kFeaturedTag = 'featured';
  static const kSortEdited = 'edited';
  static const kSortSpots = 'spots';
  static const kSortName = 'name';
  static const kSortProgress = 'progress';
  static const kSortInProgress = 'resume';
  static const kSortCoverage = 'coverage';
  static const kSortCombinedTrending = 'combinedTrending';
  static const _sortIcons = {
    kSortEdited: Icons.update,
    kSortSpots: Icons.format_list_numbered,
    kSortName: Icons.sort_by_alpha,
    kSortProgress: Icons.bar_chart,
    kSortInProgress: Icons.play_arrow,
    kSortCoverage: Icons.layers,
    kSortCombinedTrending: Icons.local_fire_department,
  };
  static final _manifestFuture = AssetManifest.instance;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _filter = 'all';
  String _sort = kSortEdited;
  bool _needsPractice = false;
  bool _loadingNeedsPractice = false;
  final Set<String> _needsPracticeIds = {};
  final Set<String> _favorites = {};
  bool _favoritesOnly = false;
  bool _inProgressOnly = false;
  bool _showRecent = true;
  bool _hideCompleted = false;
  String? _selectedTag;
  bool _importing = false;

  List<TrainingPackTemplate> _recent = [];
  List<TrainingPackTemplate> _popular = [];
  final Map<String, TrainingPackStat?> _stats = {};
  final Map<String, int> _playCounts = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) FocusScope.of(context).requestFocus(_searchFocusNode);
      });
      _maybeOfferStarter();
    });
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    await _load(prefs);
    await _autoImport(prefs);
    await _updateRecent();
    await _updatePopular();
    await _loadStats();
    await _loadPlayCounts();
  }

  Future<void> _maybeOfferStarter() async {
    final hands = context.read<SavedHandManagerService>().hands;
    if (hands.isNotEmpty) return;
    final start = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _StarterTrainingDialog(),
    );
    if (start == true && mounted) {
      final tpl = await context
          .read<TrainingPackTemplateStorageService>()
          .loadBuiltinTemplate('starter_btn_vs_bb');
      await context.read<TrainingSessionService>().startSession(tpl);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load([SharedPreferences? prefs]) async {
    prefs ??= await SharedPreferences.getInstance();
    setState(() {
      _filter = prefs.getString(_key) ?? 'all';
      _sort = prefs.getString(_sortKey) ?? kSortEdited;
      _favorites
        ..clear()
        ..addAll(prefs.getStringList(_favKey) ?? []);
      _needsPractice = prefs.getBool(_needsPracticeKey) ?? false;
      _favoritesOnly = prefs.getBool(_favOnlyKey) ?? false;
      _selectedTag = prefs.getString(_selTagKey);
      _showRecent = prefs.getBool(_recentOnlyKey) ?? true;
      _inProgressOnly = prefs.getBool(_inProgressKey) ?? false;
      _hideCompleted = prefs.getBool(_hideCompletedKey) ?? false;
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

  Future<void> _setShowRecent(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_recentOnlyKey, value);
    setState(() => _showRecent = value);
  }

  Future<void> _setInProgressOnly(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_inProgressKey, value);
    setState(() => _inProgressOnly = value);
  }

  Future<void> _setHideCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideCompletedKey, value);
    setState(() => _hideCompleted = value);
  }

  Future<void> _updateRecent() async {
    final templates = context.read<TemplateStorageService>().templates;
    final recent = await TrainingPackStatsService.recentlyPractisedTemplates(
      templates,
    );
    if (!mounted) return;
    setState(() => _recent = recent);
  }

  Future<void> _updatePopular() async {
    final templates = context.read<TemplateStorageService>().templates;
    final popular =
        await TrainingPackStatsService.mostPlayedTemplates(templates, 5);
    if (!mounted) return;
    setState(() => _popular = popular);
  }

  Future<void> _loadStats() async {
    final templates = context.read<TemplateStorageService>().templates;
    final map = <String, TrainingPackStat?>{};
    for (final t in templates) {
      map[t.id] = await TrainingPackStatsService.getStats(t.id);
    }
    if (!mounted) return;
    setState(() {
      _stats
        ..clear()
        ..addAll(map);
    });
  }

  Future<void> _loadPlayCounts() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final counts = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      counts.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
    }
    if (!mounted) return;
    setState(() {
      _playCounts
        ..clear()
        ..addAll(counts);
    });
  }

  Color _colorFor(double val) {
    if (val >= .99) return Colors.green;
    if (val >= .5) return Colors.amber;
    return Colors.red;
  }

  int _compareCombinedTrending(TrainingPackTemplate a, TrainingPackTemplate b) {
    final ta = (a as dynamic).trending == true;
    final tb = (b as dynamic).trending == true;
    final r1 = (tb ? 1 : 0).compareTo(ta ? 1 : 0);
    if (r1 != 0) return r1;
    final pa = _playCounts[a.id] ?? 0;
    final pb = _playCounts[b.id] ?? 0;
    final r2 = pb.compareTo(pa);
    if (r2 != 0) return r2;
    final r3 = b.updatedAt.compareTo(a.updatedAt);
    return r3 == 0 ? a.name.compareTo(b.name) : r3;
  }


  List<TrainingPackTemplate> _applySorting(List<TrainingPackTemplate> list) {
    final copy = [...list];
    switch (_sort) {
      case kSortCoverage:
        copy.sort((a, b) {
          final ca = a.coveragePercent;
          final cb = b.coveragePercent;
          if (ca == null && cb == null) return 0;
          if (ca == null) return 1;
          if (cb == null) return -1;
          final r = cb.compareTo(ca);
          return r == 0 ? a.name.compareTo(b.name) : r;
        });
        break;
      case kSortName:
        copy.sort((a, b) => a.name.compareTo(b.name));
        break;
      case kSortSpots:
        copy.sort((a, b) {
          final cmp = b.hands.length.compareTo(a.hands.length);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case kSortProgress:
        copy.sort((a, b) {
          final aAcc = _stats[a.id]?.accuracy ?? 0.0;
          final bAcc = _stats[b.id]?.accuracy ?? 0.0;
          final cmp = aAcc.compareTo(bAcc);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case kSortInProgress:
        copy.sort((a, b) {
          final ai = _stats[a.id]?.lastIndex ?? 0;
          final bi = _stats[b.id]?.lastIndex ?? 0;
          final cmp = bi.compareTo(ai);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
        break;
      case kSortCombinedTrending:
        copy.sort(_compareCombinedTrending);
        break;
      default:
        copy.sort((a, b) {
          final cmp = b.updatedAt.compareTo(a.updatedAt);
          return cmp == 0 ? a.name.compareTo(b.name) : cmp;
        });
    }
    return copy;
  }

  Widget _buildSortButtons(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: Text(l.sortNewest),
            selected: _sort == kSortEdited,
            onSelected: (_) => _setSort(kSortEdited),
          ),
          ChoiceChip(
            label: Text(l.sortMostHands),
            selected: _sort == kSortSpots,
            onSelected: (_) => _setSort(kSortSpots),
          ),
          ChoiceChip(
            label: Text(l.sortName),
            selected: _sort == kSortName,
            onSelected: (_) => _setSort(kSortName),
          ),
          ChoiceChip(
            label: Text(l.sortProgress),
            selected: _sort == kSortProgress,
            onSelected: (_) => _setSort(kSortProgress),
          ),
          ChoiceChip(
            label: Text(l.sortCoverage),
            selected: _sort == kSortCoverage,
            onSelected: (_) => _setSort(kSortCoverage),
          ),
          ChoiceChip(
            label: const Text('🔥 Популярное'),
            selected: _sort == kSortCombinedTrending,
            onSelected: (_) => _setSort(kSortCombinedTrending),
          ),
          ChoiceChip(
            label: const Text('In Progress'),
            selected: _sort == kSortInProgress,
            onSelected: (_) => _setSort(kSortInProgress),
          ),
        ],
      ),
    );
  }

  bool _hasTag(TrainingPackTemplate t, String tag) =>
      t.tags.any((x) => x.toLowerCase() == tag);

  bool _isStarter(TrainingPackTemplate t) => _hasTag(t, kStarterTag);

  bool _isFeatured(TrainingPackTemplate t) => _hasTag(t, kFeaturedTag);

  bool _isCompleted(String id) {
    final stat = _stats[id];
    if (stat == null) return false;
    final ev = stat.postEvPct > 0 ? stat.postEvPct : stat.preEvPct;
    final icm = stat.postIcmPct > 0 ? stat.postIcmPct : stat.preIcmPct;
    return stat.accuracy >= .9 && ev >= 80 && icm >= 80;
  }

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
    } else if (_filter == 'mistakes') {
      final service = context.read<MistakeReviewPackService>();
      visible = [for (final t in visible) if (service.hasMistakes(t.id)) t];
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
    if (_inProgressOnly) {
      visible = [
        for (final t in visible)
          if ((_stats[t.id]?.lastIndex ?? 0) > 0 &&
              (_stats[t.id]?.accuracy ?? 1.0) < 1.0)
            t
      ];
    }
    if (_hideCompleted && !_favoritesOnly) {
      visible = [
        for (final t in visible)
          if (!_isCompleted(t.id) ||
              _favorites.contains(t.id) ||
              _recent.any((e) => e.id == t.id))
            t
      ];
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

  Future<void> _top3CategoriesDrill() async {
    final tpl = await TrainingPackService.createDrillFromTopCategories(context);
    if (tpl == null) return;
    await context.read<TrainingSessionService>().startSession(tpl);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  Widget _item(TrainingPackTemplate t) {
    final l = AppLocalizations.of(context)!;
    final parts = t.version.split('.');
    final version = parts.length >= 2 ? '${parts[0]}.${parts[1]}' : t.version;
    final tags = t.tags.take(3).toList();
    final isNew =
        t.isBuiltIn && DateTime.now().difference(t.createdAt).inDays < 7;
    Widget card = Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: colorFromHex(t.defaultColor)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isStarter(t))
              Row(
                children: [
                  const Icon(Icons.rocket_launch,
                      size: 16, color: Colors.blueAccent),
                  const SizedBox(width: 4),
                  Text(l.starterBadge,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.blueAccent)),
                ],
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                if (t.isBuiltIn) ...[
                  const Icon(Icons.shield, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                if (_recent.any((e) => e.id == t.id)) ...[
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    t.name,
                    style: t.isBuiltIn
                        ? TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          )
                        : null,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: isNew
                      ? Padding(
                          key: const ValueKey('new'),
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(l.newBadge,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12)),
                        )
                      : const SizedBox.shrink(key: ValueKey('notNew')),
                ),
              ],
            ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final tag in tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white70),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: () {
          final c = translateCategory(t.category);
          final main = '${c.isEmpty ? 'Без категории' : c} • ${t.hands.length} ${l.hands} • v$version';
          final stat = _stats[t.id];
          if (stat == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(main),
                const SizedBox(height: 24),
              ],
            );
          }
          final date = DateFormat('dd MMM', Intl.getCurrentLocale()).format(stat.last);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(main),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l.accuracySemantics((stat.accuracy * 100).round()),
                      child: LinearProgressIndicator(
                        value: stat.accuracy.clamp(0.0, 1.0),
                        backgroundColor: Colors.white12,
                        color: _colorFor(stat.accuracy),
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.percentLabel((stat.accuracy * 100).round()),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${l.lastTrained}: $date',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          );
        }(),
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
    if (_isStarter(t)) {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: card,
      );
    }
    return GestureDetector(
      onLongPress: () => _showPackSheet(context, t),
      child: card,
    );
  }

  void _showPackSheet(BuildContext context, TrainingPackTemplate t) {
    UserActionLogger.instance.logThrottled('sheet_open:${t.id}');
    final service = context.read<MistakeReviewPackService>();
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _PackSheetContent(
            template: t,
            showReview: service.hasMistakes(t.id),
            onStart: () async {
              Navigator.pop(context);
              final hasMistakes = service.hasMistakes(t.id);
              final choice = await showDialog<int>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: Colors.grey[850],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(l.startTraining),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, 1),
                      child: Text(l.startTraining),
                    ),
                    if (hasMistakes)
                      TextButton(
                        onPressed: () => Navigator.pop(context, 2),
                        child: Text(l.reviewMistakesOnly),
                      ),
                  ],
                ),
              );
              if (!context.mounted) return;
              if (choice == 2) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                final tpl = await service.review(context, t.id);
                if (!context.mounted) return;
                Navigator.pop(context);
                if (tpl == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.noMistakesLeft)),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MistakeReviewScreen(template: tpl)),
                );
              } else if (choice == 1) {
                context.read<TrainingSessionService>().startSession(t);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
                );
              }
            },
            onReview: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              final tpl = await service.review(context, t.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              if (tpl == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.noMistakesLeft)),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MistakeReviewScreen(template: tpl)),
              );
            },
          ),
        ),
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
    final l = AppLocalizations.of(context)!;
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
    final featured = [
      for (final t in nonFav)
        if (t.isBuiltIn && _isFeatured(t)) t
    ]..sort(_compareCombinedTrending);
    final remaining = [
      for (final t in nonFav)
        if (!(t.isBuiltIn && _isFeatured(t))) t
    ];
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
                focusNode: _searchFocusNode,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Поиск', border: InputBorder.none),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _filter,
              underline: const SizedBox.shrink(),
              onChanged: (v) => v != null ? _setFilter(v) : null,
              items: [
                const DropdownMenuItem(value: 'all', child: Text('All')),
                const DropdownMenuItem(value: 'tournament', child: Text('Tournament')),
                const DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'mistakes', child: Text(l.filterMistakes)),
              ],
            ),
            PopupMenuButton<String>(
              icon: Icon(_sortIcons[_sort], color: Colors.white70),
              onSelected: _setSort,
              initialValue: _sort,
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: kSortEdited,
                  child: Text(AppLocalizations.of(ctx)!.sortNewest),
                ),
                PopupMenuItem(
                  value: kSortSpots,
                  child: Text(AppLocalizations.of(ctx)!.sortMostHands),
                ),
                PopupMenuItem(
                  value: kSortName,
                  child: Text(AppLocalizations.of(ctx)!.sortName),
                ),
                PopupMenuItem(
                  value: kSortProgress,
                  child: Text(AppLocalizations.of(ctx)!.sortProgress),
                ),
                PopupMenuItem(
                  value: kSortCoverage,
                  child: Text(AppLocalizations.of(ctx)!.sortCoverage),
                ),
                const PopupMenuItem(
                  value: kSortCombinedTrending,
                  child: Text('🔥 Популярное'),
                ),
                const PopupMenuItem(
                  value: kSortInProgress,
                  child: Text('In Progress'),
                ),
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
          SyncStatusIcon.of(context),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(l.favorites),
            value: _favoritesOnly,
            onChanged: _setFavoritesOnly,
            activeColor: Colors.orange,
          ),
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
                    leading: Icon(Icons.error, color: AppColors.accent),
                    title: Text(l.reviewMistakes),
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
                label: Text(l.needsPractice),
                selected: _needsPractice,
                onSelected: (v) => _updateNeedsPractice(v),
              ),
              FilterChip(
                label: Text(l.favorites),
                selected: _favoritesOnly,
                onSelected: (v) => _setFavoritesOnly(v),
              ),
              ChoiceChip(
                label: const Text('🟡 В процессе'),
                selected: _inProgressOnly,
                onSelected: (v) => _setInProgressOnly(v),
              ),
              ChoiceChip(
                label: const Text('🧹 Скрыть завершённые'),
                selected: _hideCompleted,
                onSelected: (v) => _setHideCompleted(v),
              ),
              FilterChip(
                label: Text(l.recentPacks),
                selected: _showRecent,
                onSelected: (v) => _setShowRecent(v),
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
        _buildSortButtons(l),
        if (_loadingNeedsPractice) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: hasResults
              ? ListView(
                  children: [
                    if (sortedFav.isNotEmpty) ...[
                      ListTile(title: Text('★ ${l.favorites}')),
                      for (final t in sortedFav) _item(t),
                      if (builtInStarter.isNotEmpty || builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (builtInStarter.isNotEmpty || builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ],
                    if (_recent.isNotEmpty && !_needsPractice && _showRecent) ...[
                      ListTile(title: Text(l.recentPacks)),
                      for (final t in _recent) _item(t),
                      if (featured.isNotEmpty || builtInStarter.isNotEmpty || builtInOther.isNotEmpty || user.isNotEmpty)
                        const Divider(),
                    ],
                    if (featured.isNotEmpty) ...[
                      ListTile(title: Text(l.recommended)),
                      for (final t in featured) _item(t),
                      if (builtInStarter.isNotEmpty ||
                          builtInOther.isNotEmpty ||
                          user.isNotEmpty)
                        const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (builtInStarter.isNotEmpty ||
                          builtInOther.isNotEmpty ||
                          user.isNotEmpty)
                        const Divider(),
                    ],
                    if (_popular.isNotEmpty) ...[
                      ListTile(title: Text(l.popularPacks)),
                      for (final t in _popular) _item(t),
                      if (builtInStarter.isNotEmpty ||
                          builtInOther.isNotEmpty ||
                          user.isNotEmpty)
                        const Divider(),
                    ],
                    if (builtInStarter.isNotEmpty) ...[
                      ListTile(title: Text(l.starterPacks)),
                      for (final t in builtInStarter) _item(t),
                      if (builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ]
                    else if (filteringActive) ...[
                      _emptyTile,
                      if (builtInOther.isNotEmpty || user.isNotEmpty) const Divider(),
                    ],
                    if (builtInOther.isNotEmpty) ...[
                      ListTile(title: Text(l.builtInPacks)),
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
                            Text(l.yourPacks, style: Theme.of(context).textTheme.titleMedium),
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
            heroTag: 'top3CatFab',
            onPressed: _top3CategoriesDrill,
            label: const Text('Top 3 Mistakes'),
            icon: const Icon(Icons.leaderboard),
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

class _PackSheetContent extends StatelessWidget {
  const _PackSheetContent({
    required this.template,
    this.showReview = false,
    required this.onStart,
    this.onReview,
  });
  final TrainingPackTemplate template;
  final bool showReview;
  final VoidCallback onStart;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final diffVal = (template as dynamic).difficultyLevel;
    final diff = '★' * diffVal + '☆' * (3 - diffVal);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(template.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        if (template.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(template.description),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Text('${template.hands.length} ${l.hands}'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(diff),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onStart,
          child: Text(l.startTraining),
        ),
        if (showReview) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onReview,
            child: Text(l.reviewMistakes),
          ),
        ],
      ],
    );
  }
}

class _StarterTrainingDialog extends StatelessWidget {
  const _StarterTrainingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Practice most common push/fold spots to build skill quickly',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Start Training Now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
