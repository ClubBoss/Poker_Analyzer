import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:convert';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';
import '../services/training_pack_asset_loader.dart';
import 'package:uuid/uuid.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/session_log.dart';

import '../models/v2/training_pack_template.dart';
import '../services/template_storage_service.dart';
import '../helpers/training_pack_storage.dart';
import '../helpers/training_pack_validator.dart';
import '../services/training_pack_author_service.dart' show TrainingPackAuthorService, PresetConfig;
import '../models/v2/hero_position.dart';
import '../services/favorite_pack_service.dart';
import '../services/training_stats_service.dart';
import '../utils/template_coverage_utils.dart';
import '../services/training_pack_filter_memory_service.dart';
import 'v2/training_pack_template_editor_screen.dart';
import 'training_session_screen.dart';
import 'pack_preview_screen.dart';
import '../widgets/combined_progress_bar.dart';
import '../widgets/street_coverage_bar.dart';

enum _StackRange { l8, b9_12, b13_20 }

enum _SortMode { name, newest, progress, favorite, rating, coverage }

extension _StackRangeExt on _StackRange {
  String get label {
    switch (this) {
      case _StackRange.l8:
        return '≤8 BB';
      case _StackRange.b9_12:
        return '9-12 BB';
      case _StackRange.b13_20:
        return '13-20 BB';
    }
  }

  bool contains(int v) {
    switch (this) {
      case _StackRange.l8:
        return v <= 8;
      case _StackRange.b9_12:
        return v >= 9 && v <= 12;
      case _StackRange.b13_20:
        return v >= 13 && v <= 20;
    }
  }
}

class PacksLibraryScreen extends StatefulWidget {
  const PacksLibraryScreen({super.key});

  @override
  State<PacksLibraryScreen> createState() => _PacksLibraryScreenState();
}

class _PacksLibraryScreenState extends State<PacksLibraryScreen> {
  final List<TrainingPackTemplate> _packs = [];
  bool _loaded = false;
  String _query = '';
  String? _difficultyFilter;
  final Set<String> _statusFilters = {};
  final Set<HeroPosition> _posFilters = {};
  final Set<_StackRange> _stackFilters = {};
  final Set<String> _selectedTags = {};
  final Set<String> _themeFilters = {};
  /// Current grouping mode: 'tag', 'position', 'stack' or 'none'.
  String _currentGroupKey = 'none';
  final Set<String> _mistakePacks = {};
  _SortMode _sortMode = _SortMode.name;
  String _sortOrder = 'newest';
  Map<String, int> _playCounts = {};
  Map<String, int> _trainedHands = {};
  Map<String, double> _ratings = {};
  bool _compactMode = false;
  static const _PrefsKey = 'pack_library_state';

  List<String> get _availableTags {
    final counts = <String, int>{};
    for (final p in _packs) {
      for (final t in p.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries) e.key];
  }

  List<String> get _availableThemes {
    final set = <String>{};
    for (final p in _packs) {
      final th = p.meta['theme']?.toString();
      if (th != null && th.isNotEmpty) set.add(th);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  void initState() {
    super.initState();
    _restoreState().then((_) {
      _loaded = true;
      _load();
      _loadPlayCounts();
    });
  }

  List<TrainingPackTemplate> get _filtered {
    final fav = context.read<FavoritePackService>();
    final res = _packs.where((p) {
      final q = _query.toLowerCase();
      final diffOk =
          _difficultyFilter == null || p.difficulty == _difficultyFilter;
      final textOk = p.name.toLowerCase().contains(q) ||
          (p.difficulty?.toLowerCase().contains(q) ?? false);
      var statusOk = true;
      if (_statusFilters.isNotEmpty) {
        final now = DateTime.now();
        final total = p.totalWeight;
        final evPct = total == 0 ? 0 : p.evCovered * 100 / total;
        final icmPct = total == 0 ? 0 : p.icmCovered * 100 / total;
        final isNew = now.difference(p.createdAt).inDays < 3;
        final isCompleted = p.evCovered + p.icmCovered >= total * 2;
        final isIncomplete = evPct < 50 || icmPct < 50;
        statusOk = false;
        if (_statusFilters.contains('New') && isNew) statusOk = true;
        if (_statusFilters.contains('Completed') && isCompleted) statusOk = true;
        if (_statusFilters.contains('Incomplete') && isIncomplete) statusOk = true;
      }
      if (_statusFilters.contains('Favorites') && !fav.isFavorite(p.id)) {
        statusOk = false;
      }
      final posOk = _posFilters.isEmpty || _posFilters.contains(p.heroPos);
      var stackOk = true;
      if (_stackFilters.isNotEmpty) {
        stackOk = false;
        for (final r in _stackFilters) {
          if (r.contains(p.heroBbStack)) {
            stackOk = true;
            break;
          }
        }
      }
      final tagOk =
          _selectedTags.isEmpty || p.tags.any(_selectedTags.contains);
      final theme = p.meta['theme']?.toString();
      final themeOk = _themeFilters.isEmpty ||
          (theme != null && _themeFilters.contains(theme));
      return diffOk && textOk && statusOk && posOk && stackOk && tagOk && themeOk;
    }).toList();
    res.sort((a, b) {
      if (_sortMode == _SortMode.rating) {
        final ra = _ratings[a.id] ?? 0.0;
        final rb = _ratings[b.id] ?? 0.0;
        final r = rb.compareTo(ra);
        if (r != 0) return r;
      } else if (_sortMode == _SortMode.coverage) {
        double cov(TrainingPackTemplate t) => t.coveragePercent ?? -1;
        final r = cov(b).compareTo(cov(a));
        if (r != 0) return r;
      }
      switch (_sortOrder) {
        case 'popular':
          final pa = _playCounts[a.id] ?? 0;
          final pb = _playCounts[b.id] ?? 0;
          final r = pb.compareTo(pa);
          if (r != 0) return r;
          return b.createdAt.compareTo(a.createdAt);
        case 'mostSpots':
          final r = b.totalWeight.compareTo(a.totalWeight);
          if (r != 0) return r;
          return b.createdAt.compareTo(a.createdAt);
        case 'newest':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });
    return res;
  }

  Future<void> _load() async {
    final prefs = await PreferencesService.getInstance();
    final list = TrainingPackAssetLoader.instance.getAll();
    list.sort((a, b) {
      final d1 = b.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final d2 = a.lastTrainedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      if (d1 != d2) return d1.compareTo(d2);
      final covA = a.evCovered + a.icmCovered;
      final covB = b.evCovered + b.icmCovered;
      return covB.compareTo(covA);
    });
    final mistakes = <String>{};
    for (final p in list) {
      if (prefs.getBool('mistakes_tpl_${p.id}') ?? false) {
        mistakes.add(p.id);
      }
    }
    if (mounted) {
      setState(() {
        _packs.addAll(list);
        _mistakePacks
          ..clear()
          ..addAll(mistakes);
      });
    }
  }

  Future<void> _loadPlayCounts() async {
    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');
    final counts = <String, int>{};
    final hands = <String, int>{};
    final mistakes = <String, int>{};
    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      counts.update(log.templateId, (c) => c + 1, ifAbsent: () => 1);
      final total = log.correctCount + log.mistakeCount;
      hands.update(log.templateId, (c) => c + total, ifAbsent: () => total);
      mistakes.update(log.templateId, (c) => c + log.mistakeCount,
          ifAbsent: () => log.mistakeCount);
    }
    final ratings = <String, double>{};
    for (final id in hands.keys) {
      final h = hands[id] ?? 0;
      final m = mistakes[id] ?? 0;
      if (h > 0) {
        final r = 5.0 - (m / h) * 2.5;
        ratings[id] = double.parse(r.clamp(1.0, 5.0).toStringAsFixed(1));
      }
    }
    if (mounted) {
      setState(() {
        _playCounts = counts;
        _trainedHands = hands;
        _ratings = ratings;
      });
    }
  }

  Future<void> _restoreState() async {
    final prefs = await PreferencesService.getInstance();
    final data = prefs.getString(_PrefsKey);
    if (data != null) {
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        setState(() {
          _query = json['query'] as String? ?? '';
          _statusFilters
            ..clear()
            ..addAll([for (final s in json['status'] as List? ?? []) s as String]);
          final sort = json['sort'] as int?;
          if (sort != null && sort >= 0 && sort < _SortMode.values.length) {
            _sortMode = _SortMode.values[sort];
          }
          _sortOrder = json['order'] as String? ?? 'newest';
          _compactMode = json['compact'] as bool? ?? false;
          final g = json['group'] as String? ?? json['groupTag'] as String?;
          if (g is String && g.isNotEmpty) {
            _currentGroupKey = g;
          }
          _themeFilters
            ..clear()
            ..addAll([for (final t in json['themes'] as List? ?? []) t as String]);
        });
      } catch (_) {}
    }

    final memory = TrainingPackFilterMemoryService.instance;
    await memory.load();
    setState(() {
      _difficultyFilter = memory.difficulty;
      _selectedTags
        ..clear()
        ..addAll(memory.selectedTags);
      _stackFilters
        ..clear()
        ..addAll([
          for (final i in memory.stackFilters)
            if (i >= 0 && i < _StackRange.values.length) _StackRange.values[i]
        ]);
      _posFilters
        ..clear()
        ..addAll(memory.positionFilters);
      _themeFilters
        ..clear()
        ..addAll(memory.themeFilters);
      if (memory.groupByTag) {
        _currentGroupKey = 'tag';
      } else if (memory.groupByPosition) {
        _currentGroupKey = 'position';
      } else if (memory.groupByStack) {
        _currentGroupKey = 'stack';
      } else {
        _currentGroupKey = 'none';
      }
    });
  }

  Future<void> _saveState() async {
    await TrainingPackFilterMemoryService.instance.update(
      tags: _selectedTags,
      stack: {for (final r in _stackFilters) r.index},
      pos: _posFilters,
      themes: _themeFilters,
      difficulty: _difficultyFilter,
      groupByTag: _currentGroupKey == 'tag',
      groupByPosition: _currentGroupKey == 'position',
      groupByStack: _currentGroupKey == 'stack',
    );
    final prefs = await PreferencesService.getInstance();
    final json = jsonEncode({
      'query': _query,
      'status': _statusFilters.toList(),
      'pos': [for (final p in _posFilters) p.name],
      'stack': [for (final r in _stackFilters) r.index],
      'tags': _selectedTags.toList(),
      'themes': _themeFilters.toList(),
      'group': _currentGroupKey,
      'difficulty': _difficultyFilter,
      'sort': _sortMode.index,
      'order': _sortOrder,
      'compact': _compactMode,
    });
    await prefs.setString(_PrefsKey, json);
  }

  Future<void> _import(TrainingPackTemplate tpl) async {
    final templates = await TrainingPackStorage.load();
    final newTpl = tpl.copyWith(id: const Uuid().v4(), createdAt: DateTime.now());
    templates.add(newTpl);
    await TrainingPackStorage.save(templates);
    context.read<TemplateStorageService>().addTemplate(newTpl);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingPackTemplateEditorScreen(template: newTpl, templates: templates),
      ),
    );
  }

  Future<void> _createFromPreset(String id,
      {int? stack, HeroPosition? pos}) async {
    final templates = await TrainingPackStorage.load();
    final tpl = TrainingPackAuthorService.generateFromPreset(id, stack: stack)
        .copyWith(id: const Uuid().v4(), createdAt: DateTime.now());
    if (pos != null) {
      tpl.heroPos = pos;
      for (final s in tpl.spots) {
        s.hand.position = pos;
      }
    }
    templates.add(tpl);
    await TrainingPackStorage.save(templates);
    context.read<TemplateStorageService>().addTemplate(tpl);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TrainingPackTemplateEditorScreen(template: tpl, templates: templates),
      ),
    );
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.packCreated(tpl.name))));
  }

  Future<void> _resetPack(TrainingPackTemplate pack) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.resetPackPrompt(pack.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.reset),
          ),
        ],
      ),
    );
    if (ok != true) return;
    for (final s in pack.spots) {
      final hero = s.hand.heroIndex;
      for (final a in s.hand.actions[0] ?? []) {
        if (a.playerIndex == hero) {
          a.ev = null;
          a.icmEv = null;
        }
      }
      s.evalResult = null;
      s.correctAction = null;
      s.explanation = null;
      s.dirty = false;
    }
    pack.lastTrainedAt = null;
    TemplateCoverageUtils.recountAll(pack).applyTo(pack.meta);
    final list = await TrainingPackStorage.load();
    final idx = list.indexWhere((e) => e.id == pack.id);
    if (idx != -1) list[idx] = pack;
    await TrainingPackStorage.save(list);
    if (mounted) setState(() {});
    TrainingStatsService.instance?.notifyListeners();
  }


  void _resetFilters() {
    setState(() {
      _selectedTags.clear();
      _stackFilters.clear();
      _themeFilters.clear();
      _difficultyFilter = null;
      _query = '';
      _currentGroupKey = 'none';
    });
    TrainingPackFilterMemoryService.instance.reset();
    _saveState();
  }

  Widget _buildCompactTile(TrainingPackTemplate t) {
    final total = t.totalWeight;
    final trained = _trainedHands[t.id] ?? 0;
    final done = trained.clamp(0, total);
    final ratio = total == 0 ? 0 : done * 100 / total;
    return Card(
      child: ListTile(
        dense: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.meta['theme'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Chip(
                  label: Text(t.meta['theme'].toString(),
                      style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.blueGrey,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity:
                      const VisualDensity(horizontal: -4, vertical: -4),
                ),
              ),
            Text(t.name),
          ],
        ),
        subtitle: t.tags.isNotEmpty
            ? Wrap(
                spacing: 4,
                runSpacing: 2,
                children: [
                  for (final tag in t.tags.take(3))
                    Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey[800],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                  if (t.tags.length > 3)
                    Chip(
                      label: Text('+${t.tags.length - 3}',
                          style: const TextStyle(fontSize: 11)),
                      backgroundColor: Colors.grey[800],
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          const VisualDensity(horizontal: -4, vertical: -4),
                    ),
                ],
              )
            : null,
        trailing: Text('$done / $total (${ratio.round()}%)',
            style: const TextStyle(fontSize: 12)),
        onTap: () => _import(t),
      ),
    );
  }

  Widget _buildPackTile(TrainingPackTemplate t) {
    if (_compactMode) return _buildCompactTile(t);
    final isNew =
        DateTime.now().difference(t.createdAt).inDays < 3;
    final isUpdated = t.updatedDate != null &&
        DateTime.now().difference(t.updatedDate!).inDays < 3;
    final total = t.totalWeight;
    final trained = _trainedHands[t.id] ?? 0;
    final done = trained.clamp(0, total);
    final ratio = total == 0 ? 0.0 : done / total;
    final evDone = t.spots
        .where((s) => s.heroEv != null && !s.dirty)
        .fold(0, (a, b) => a + b.priority);
    final icmDone = t.spots
        .where((s) => s.heroIcmEv != null && !s.dirty)
        .fold(0, (a, b) => a + b.priority);
    final solvedAll =
        t.spots.every((s) => s.heroEv != null && s.heroIcmEv != null);
    final coveragePct = total == 0
        ? 0
        : ((t.evCovered + t.icmCovered) * 100 / (2 * total)).round();
    final fav = context.read<FavoritePackService>();
    final rating = _ratings[t.id];
    double pct(int done) => total == 0 ? 0 : done * 100 / total;
    return ListTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.meta['theme'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Chip(
                label: Text(t.meta['theme'].toString()),
                backgroundColor: Colors.blueGrey,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(t.name),
                    if (isUpdated)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('🆕', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              if (rating != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (t.difficulty != null)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.difficulty == 'Beginner'
                            ? Colors.green
                            : t.difficulty == 'Intermediate'
                                ? Colors.orange
                                : t.difficulty == 'Advanced'
                                    ? Colors.red
                                    : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.difficulty!,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  if (isNew)
                    const Chip(
                      label: Text('NEW'),
                      backgroundColor: Colors.amber,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          VisualDensity(horizontal: -4, vertical: -4),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Coverage: $coveragePct%',
            style: TextStyle(
              fontSize: 11,
              color: coveragePct < 70
                  ? Colors.grey
                  : coveragePct >= 90
                      ? Colors.green
                      : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          CombinedProgressBar(pct(evDone), pct(icmDone)),
          const SizedBox(height: 4),
          StreetCoverageBar(
            t.streetTotals(),
            t.streetCovered(),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          (() {
            final updated = t.updatedDate;
            final diff = updated == null
                ? null
                : DateTime.now().difference(updated).inDays;
            String? label;
            if (diff != null) {
              if (diff > 30) {
                label =
                    'Updated: ${DateFormat('d MMM', 'en_US').format(updated)}';
              } else if (diff < 3) {
                label = 'Updated Recently';
              }
            }
            if (label == null && t.lastTrainedAt == null) return null;
            return Row(
              children: [
                if (label != null)
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white38)),
                if (label != null && t.lastTrainedAt != null)
                  const SizedBox(width: 8),
                if (t.lastTrainedAt != null)
                  Text(
                    'Trained ${timeago.format(t.lastTrainedAt!, locale: "en_short")}',
                    style: const TextStyle(fontSize: 11, color: Colors.white54),
                  ),
              ],
            );
          })(),
          Text(t.description),
          if (t.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SizedBox(
                height: 28,
                child: Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    for (final tag in t.tags.take(3))
                      Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey[800],
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    if (t.tags.length > 3)
                      Chip(
                        label: Text('+${t.tags.length - 3}',
                            style: const TextStyle(fontSize: 11)),
                        backgroundColor: Colors.grey[800],
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity:
                            const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                  ],
                ),
              ),
            ),
          if (total > 0)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$done / $total (${(ratio * 100).round()}%)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
        ],
      ),
      leading: CircleAvatar(child: Text(total.toString())),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              fav.isFavorite(t.id) ? Icons.star : Icons.star_border,
            ),
            color: fav.isFavorite(t.id) ? Colors.amber : Colors.white54,
            onPressed: () => fav.toggle(t.id),
          ),
          if (validateTrainingPackTemplate(t).isEmpty &&
              !context
                  .read<TemplateStorageService>()
                  .templates
                  .any((e) => e.name == t.name))
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ElevatedButton(
                onPressed: () async {
                  final newSession = await context
                      .read<TrainingSessionService>()
                      .startFromTemplate(t);
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrainingSessionScreen(session: newSession),
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PackPreviewScreen(pack: t),
                  ),
                );
              },
              child: const Text('Preview'),
            ),
          ),
          if (_mistakePacks.contains(t.id))
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: OutlinedButton(
                onPressed: () async {
                  final session = await context
                      .read<TrainingSessionService>()
                      .startFromPastMistakes(t);
                  if (session == null) {
                    final prefs = await PreferencesService.getInstance();
                    await prefs.setBool('mistakes_tpl_${t.id}', false);
                    if (mounted) {
                      setState(() => _mistakePacks.remove(t.id));
                    }
                    return;
                  }
                  if (!context.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TrainingSessionScreen(session: session),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.reviewMistakes),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.play_circle_fill),
            tooltip: solvedAll ? 'All solved' : 'Resume',
            onPressed: solvedAll
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => TrainingSessionScreen(template: t)),
                    );
                  },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'import') _import(t);
              if (v == 'preview') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPackTemplateEditorScreen(
                      template: t,
                      templates: [t],
                      readOnly: true,
                    ),
                  ),
                );
              }
              if (v == 'reset') _resetPack(t);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'import', child: Text('Import')),
              PopupMenuItem(value: 'preview', child: Text('Preview')),
              PopupMenuItem(value: 'reset', child: Text('Reset progress')),
            ],
          )
        ],
      ),
      onTap: () => _import(t),
    );
  }

  void _showPresetSheet() {
    final presets = TrainingPackAuthorService.presetConfigs;
    var id = presets.keys.first;
    var stack = presets[id]!.stack.toDouble();
    var pos = presets[id]!.pos;
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: id,
                decoration: const InputDecoration(labelText: 'Type'),
                items: [
                  for (final e in presets.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value.name))
                ],
                onChanged: (v) {
                  if (v != null) {
                    set(() {
                      id = v;
                      stack = presets[v]!.stack.toDouble();
                      pos = presets[v]!.pos;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: stack,
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '${stack.round()} bb',
                      onChanged: (v) => set(() => stack = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${stack.round()} bb')
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HeroPosition>(
                value: pos,
                decoration: const InputDecoration(labelText: 'Position'),
                items: [
                  for (final p in HeroPosition.values)
                    DropdownMenuItem(value: p, child: Text(p.label))
                ],
                onChanged: (v) => set(() => pos = v ?? pos),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx,
                    {'id': id, 'stack': stack.round(), 'pos': pos}),
                child: const Text('Generate'),
              )
            ],
          ),
        ),
      ),
    ).then((res) {
      if (res != null) {
        _createFromPreset(res['id'] as String,
            stack: res['stack'] as int, pos: res['pos'] as HeroPosition);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pack Library'),
        actions: [
          TextButton.icon(
            onPressed: _showPresetSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _packs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Builder(
                  builder: (context) {
                    final session =
                        context.read<TrainingSessionService>().currentSession;
                    final template = context.read<TrainingSessionService>().template;
                    if (session == null || session.isCompleted || template == null) {
                      return const SizedBox.shrink();
                    }
                    final progress =
                        (session.index / template.totalWeight * 100).clamp(0, 100);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(template.name,
                                        style: const TextStyle(fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${session.index + 1} / ${template.totalWeight}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 4),
                                    CombinedProgressBar(progress, progress),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TrainingSessionScreen(session: session),
                                    ),
                                  );
                                },
                                child: const Text('Resume'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Builder(
                  builder: (context) {
                    final suggest = _packs
                        .where((p) =>
                            (p.evCovered + p.icmCovered) < p.totalWeight * 2)
                        .minBy((p) =>
                            (p.evCovered + p.icmCovered) / p.totalWeight);
                    if (suggest == null) return const SizedBox.shrink();
                    final total = suggest.totalWeight;
                    final evPct =
                        total == 0 ? 0 : suggest.evCovered * 100 / total;
                    final icmPct =
                        total == 0 ? 0 : suggest.icmCovered * 100 / total;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Suggested pack'),
                                    const SizedBox(height: 4),
                                    Text(suggest.name,
                                        style:
                                            const TextStyle(fontSize: 16)),
                                    const SizedBox(height: 4),
                                    CombinedProgressBar(evPct, icmPct),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final newSession = await context
                                      .read<TrainingSessionService>()
                                      .startFromTemplate(suggest);
                                  if (!context.mounted) return;
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TrainingSessionScreen(session: newSession),
                                    ),
                                  );
                                },
                                child: const Text('Start'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search packs…',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() => _query = '');
                                      _saveState();
                                    },
                                  ),
                          ),
                          onChanged: (v) {
                            setState(() => _query = v.trim());
                            _saveState();
                          },
                        ),
                      ),
                      PopupMenuButton<_SortMode>(
                        icon: const Icon(Icons.sort),
                        onSelected: (v) {
                          setState(() => _sortMode = v);
                          _saveState();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: _SortMode.name, child: Text(l.sortName)),
                          PopupMenuItem(
                              value: _SortMode.newest, child: Text(l.sortNewest)),
                          PopupMenuItem(
                              value: _SortMode.progress, child: Text(l.sortProgress)),
                          PopupMenuItem(
                              value: _SortMode.favorite, child: Text(l.favorites)),
                          PopupMenuItem(
                              value: _SortMode.rating,
                              child: Text(l.sortRating)),
                          PopupMenuItem(
                              value: _SortMode.coverage,
                              child: Text(l.sortCoverage)),
                        ],
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final d in ['Beginner', 'Intermediate', 'Advanced'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(d),
                            selected: _difficultyFilter == d,
                            onSelected: (_) {
                              setState(() =>
                                  _difficultyFilter == d
                                      ? _difficultyFilter = null
                                      : _difficultyFilter = d);
                              _saveState();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ['New', 'Completed', 'Incomplete', 'Favorites'])
                        FilterChip(
                          label: Text(s),
                          selected: _statusFilters.contains(s),
                          onSelected: (_) {
                            setState(() {
                              _statusFilters.contains(s)
                                  ? _statusFilters.remove(s)
                                  : _statusFilters.add(s);
                            });
                            _saveState();
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final p in kPositionOrder)
                        FilterChip(
                          label: Text(p.label),
                          selected: _posFilters.contains(p),
                          onSelected: (_) {
                            setState(() {
                              _posFilters.contains(p)
                                  ? _posFilters.remove(p)
                                  : _posFilters.add(p);
                            });
                            _saveState();
                          },
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final r in _StackRange.values)
                        FilterChip(
                          label: Text(r.label),
                          selected: _stackFilters.contains(r),
                          onSelected: (_) {
                            setState(() {
                              _stackFilters.contains(r)
                                  ? _stackFilters.remove(r)
                                  : _stackFilters.add(r);
                            });
                            _saveState();
                          },
                        ),
                    ],
                  ),
                ),
                if (_availableThemes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final th in _availableThemes)
                          FilterChip(
                            label: Text(th),
                            selected: _themeFilters.contains(th),
                            onSelected: (_) {
                              setState(() {
                                _themeFilters.contains(th)
                                    ? _themeFilters.remove(th)
                                    : _themeFilters.add(th);
                              });
                              _saveState();
                            },
                          ),
                      ],
                    ),
                  ),
                StreamBuilder<Set<String>>(
                  stream: context.read<FavoritePackService>().favorites$,
                  builder: (context, _) {
                    final c = _filtered.length;
                    final text = c == 0
                        ? AppLocalizations.of(context)!.noResults
                        : AppLocalizations.of(context)!.packsShown(c);
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          text,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (_packs.any((p) => p.tags.isNotEmpty))
                  Column(
                    children: [
                      TrainingPackTagFilterBar(
                        availableTags: _availableTags,
                        initialSelection: _selectedTags,
                        onChanged: (tags) {
                          setState(() {
                            _selectedTags
                              ..clear()
                              ..addAll(tags);
                          });
                          _saveState();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            TextButton(
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.redAccent),
                              onPressed: _resetFilters,
                              child: Text(AppLocalizations.of(context)!.resetFilters),
                            ),
                            const SizedBox(width: 8),
                            const Text('Group'),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _currentGroupKey,
                              dropdownColor: AppColors.cardBackground,
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(
                                    value: 'none', child: Text('None')),
                                DropdownMenuItem(
                                    value: 'tag', child: Text('By Tag')),
                                DropdownMenuItem(
                                    value: 'position', child: Text('By Position')),
                                DropdownMenuItem(
                                    value: 'stack', child: Text('By Stack')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _currentGroupKey = v);
                                _saveState();
                              },
                            ),
                            const SizedBox(width: 16),
                            Text(AppLocalizations.of(context)!.sortLabel),
                            const SizedBox(width: 4),
                            DropdownButton<String>(
                              value: _sortOrder,
                              dropdownColor: AppColors.cardBackground,
                              style: const TextStyle(color: Colors.white),
                              items: [
                                DropdownMenuItem(value: 'newest', child: Text(l.sortNewest)),
                                DropdownMenuItem(value: 'popular', child: Text(l.sortPopular)),
                                DropdownMenuItem(value: 'mostSpots', child: Text(l.sortMostHands)),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _sortOrder = v);
                                _saveState();
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                  _compactMode ? Icons.view_list : Icons.view_module),
                              tooltip: _compactMode ? 'Expanded view' : 'Compact view',
                              onPressed: () {
                                setState(() => _compactMode = !_compactMode);
                                _saveState();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                Expanded(
                  child: StreamBuilder<Set<String>>(
                    stream:
                        context.read<FavoritePackService>().favorites$,
                    builder: (context, _) {
                      final filtered = _filtered;
                      if (filtered.isEmpty &&
                          (_query.isNotEmpty || _difficultyFilter != null)) {
                        return Center(child: Text(AppLocalizations.of(context)!.noResults));
                      }
                      if (_currentGroupKey != 'none') {
                        final groups = <String, List<TrainingPackTemplate>>{};
                        for (final t in filtered) {
                          var key = 'Other';
                          switch (_currentGroupKey) {
                            case 'tag':
                              key = t.tags.isNotEmpty ? t.tags.first : 'Other';
                              break;
                            case 'position':
                              key = t.heroPos.label;
                              break;
                            case 'stack':
                              final r = _StackRange.values.firstWhere(
                                  (e) => e.contains(t.heroBbStack),
                                  orElse: () => _StackRange.b13_20);
                              key = r.label;
                              break;
                          }
                          groups.putIfAbsent(key, () => []).add(t);
                        }
                        final keys = groups.keys.toList();
                        if (_currentGroupKey == 'position') {
                          keys.sort((a, b) {
                            int ia = kPositionOrder
                                .indexWhere((p) => p.label == a);
                            int ib = kPositionOrder
                                .indexWhere((p) => p.label == b);
                            ia = ia < 0 ? kPositionOrder.length : ia;
                            ib = ib < 0 ? kPositionOrder.length : ib;
                            return ia.compareTo(ib);
                          });
                        } else if (_currentGroupKey == 'stack') {
                          keys.sort((a, b) {
                            final int ia = _StackRange.values
                                .indexWhere((r) => r.label == a);
                            final int ib = _StackRange.values
                                .indexWhere((r) => r.label == b);
                            return ia.compareTo(ib);
                          });
                        } else {
                          keys.sort();
                        }
                        return ListView(
                          children: [
                            for (final k in keys)
                              ExpansionTile(
                                title: Text(k),
                                children: [
                                  for (final t in groups[k]!) _buildPackTile(t)
                                ],
                              )
                          ],
                        );
                      }
                      if (_compactMode) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final count = constraints.maxWidth < 360 ? 1 : 2;
                            return GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: count,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 3.5,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => _buildPackTile(filtered[i]),
                            );
                          },
                        );
                      }
                      return ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _buildPackTile(filtered[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        ],
      ),
    )
  }
}

