import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../services/pack_import_service.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/v2/hand_data.dart';
import '../../models/v2/hero_position.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/game_type.dart';
import '../../helpers/training_pack_storage.dart';
import '../../services/pack_generator_service.dart';
import '../../services/training_spot_storage_service.dart';
import '../../services/saved_hand_manager_service.dart';
import '../../helpers/template_coverage_utils.dart';
import '../../services/training_pack_template_ui_service.dart';
import '../../models/saved_hand.dart';
import '../../models/action_entry.dart';
import '../../services/generated_pack_history_service.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'training_pack_template_editor_screen.dart';
import '../../widgets/range_matrix_picker.dart';
import '../../widgets/preset_range_buttons.dart';
import '../training_session_screen.dart';
import '../../services/training_session_service.dart';
import '../../helpers/hand_utils.dart';
import '../../helpers/hand_type_utils.dart';
import 'training_pack_play_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/mistake_review_pack_service.dart';
import '../../services/mixed_drill_history_service.dart';
import '../../models/mixed_drill_stat.dart';
import '../../services/bulk_evaluator_service.dart';
import '../../services/offline_evaluator_service.dart';
import '../../services/theme_service.dart';
import '../../services/session_log_service.dart';

import 'package:timeago/timeago.dart' as timeago;
class TrainingPackTemplateListScreen extends StatefulWidget {
  const TrainingPackTemplateListScreen({super.key});

  @override
  State<TrainingPackTemplateListScreen> createState() =>
      _TrainingPackTemplateListScreenState();
}

class _TrainingPackTemplateListScreenState
    extends State<TrainingPackTemplateListScreen> {
  static const _prefsHideKey = 'tpl_hide_completed';
  static const _prefsGroupKey = 'tpl_group_by_street';
  static const _prefsTypeKey = 'tpl_group_by_type';
  static const _prefsMixedHandKey = 'tpl_mixed_handgoal_only';
  static const _prefsMixedCountKey = 'tpl_mixed_count';
  static const _prefsMixedStreetKey = 'tpl_mixed_street';
  static const _prefsMixedAutoKey = 'tpl_mixed_auto';
  static const _prefsEndlessKey = 'tpl_endless_drill';
  static const _prefsFavoritesKey = 'tpl_favorites';
  final List<TrainingPackTemplate> _templates = [];
  bool _loading = false;
  String _query = '';
  late TextEditingController _searchCtrl;
  final Set<String> _tagFilters = {};
  TrainingPackTemplate? _lastRemoved;
  int _lastIndex = 0;
  GameType? _selectedType;
  String? _selectedTag;
  bool _filtersShown = false;
  bool _completedOnly = false;
  bool _hideCompleted = false;
  bool _groupByStreet = false;
  bool _groupByType = false;
  bool _icmOnly = false;
  String _sort = 'name';
  List<GeneratedPackInfo> _history = [];
  int _mixedCount = 20;
  bool _mixedAutoOnly = false;
  bool _endlessDrill = false;
  String _mixedStreet = 'any';
  bool _mixedHandGoalOnly = false;
  DateTime? _mixedLastRun;
  String? _lastOpenedId;
  final Map<String, int> _progress = {};
  final Map<String, int> _streetProgress = {};
  final Map<String, Map<String, int>> _handGoalProgress = {};
  final Map<String, Map<String, int>> _handGoalTotal = {};
  final Set<String> _favorites = {};
  bool _showFavoritesOnly = false;
  bool _showNeedsEvalOnly = false;
  bool _autoEvalRunning = false;
  Timer? _autoEvalTimer;
  bool _autoEvalQueued = false;

  List<GeneratedPackInfo> _dedupHistory() {
    final map = <String, GeneratedPackInfo>{};
    for (final h in _history) {
      final existing = map[h.id];
      if (existing == null || h.ts.isAfter(existing.ts)) {
        map[h.id] = h;
      }
    }
    final list = map.values.toList()
      ..sort((a, b) => b.ts.compareTo(a.ts));
    return list;
  }

  void _sortTemplates() {
    switch (_sort) {
      case 'created':
        _templates.sort((a, b) {
          final r = b.createdAt.compareTo(a.createdAt);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'spots':
        _templates.sort((a, b) {
          final r = b.spots.length.compareTo(a.spots.length);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'tag':
        _templates.sort((a, b) {
          final tagA = a.tags.isNotEmpty ? a.tags.first.toLowerCase() : '';
          final tagB = b.tags.isNotEmpty ? b.tags.first.toLowerCase() : '';
          final r = tagA.compareTo(tagB);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      case 'last_trained':
        final logs = context.read<SessionLogService>().logs;
        final map = <String, DateTime>{};
        for (final l in logs) {
          final cur = map[l.templateId];
          if (cur == null || l.completedAt.isAfter(cur)) {
            map[l.templateId] = l.completedAt;
          }
        }
        _templates.sort((a, b) {
          final aDt = map[a.id] ?? a.createdAt;
          final bDt = map[b.id] ?? b.createdAt;
          final r = bDt.compareTo(aDt);
          return r == 0
              ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
              : r;
        });
        break;
      default:
        _templates.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, int>{};
    final streetMap = <String, int>{};
    final handMap = <String, Map<String, int>>{};
    final handTotalMap = <String, Map<String, int>>{};
    for (final t in _templates) {
      final v = prefs.getInt('tpl_prog_${t.id}');
      if (v != null) map[t.id] = v;
      final sv = prefs.getInt('tpl_street_${t.id}');
      if (sv != null) streetMap[t.id] = sv;
      final hvStr = prefs.getString('tpl_hand_${t.id}');
      final progress = <String, int>{};
      if (hvStr != null) {
        final data = jsonDecode(hvStr);
        if (data is Map) {
          for (final e in data.entries) {
            progress[e.key as String] = (e.value as num).toInt();
          }
        }
      } else {
        final hv = prefs.getInt('tpl_hand_${t.id}');
        if (hv != null && t.focusHandTypes.isNotEmpty) {
          progress[t.focusHandTypes.first.label] = hv;
        }
      }
      handMap[t.id] = progress;
      if (t.focusHandTypes.isNotEmpty) {
        final totals = <String, int>{};
        for (final g in t.focusHandTypes) {
          int total = 0;
          for (final s in t.spots) {
            final code = handCode(s.hand.heroCards);
            if (code != null && matchHandTypeLabel(g.label, code)) {
              total++;
            }
          }
          totals[g.label] = total;
        }
        handTotalMap[t.id] = totals;
      }
    }
    if (!mounted) return;
    setState(() {
      _progress..clear()..addAll(map);
      _streetProgress..clear()..addAll(streetMap);
      _handGoalProgress..clear()..addAll(handMap);
      _handGoalTotal..clear()..addAll(handTotalMap);
    });
    _maybeShowStreetReminder();
    await _maybeShowContinueReminder();
  }

  void _maybeShowStreetReminder() {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final byStreet = <String, List<double>>{};
    for (final t in _templates) {
      final s = t.targetStreet;
      if (s == null || t.streetGoal <= 0) continue;
      final val = _streetProgress[t.id] ?? 0;
      byStreet.putIfAbsent(s, () => []).add(val / t.streetGoal);
    }
    String? street;
    double best = 1;
    for (final e in byStreet.entries) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      if (avg < best) {
        best = avg;
        street = e.key;
      }
    }
    if (street == null || best >= 0.7) return;
    final tpl = _suggestTemplate(street);
    if (tpl == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Low ${_streetName(street)} progress'),
        action: SnackBarAction(
          label: 'Try Now',
          onPressed: () async {
            await _showStreetProgress(tpl);
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TrainingPackPlayScreen(template: tpl, original: tpl),
              ),
            );
            if (mounted) {
              await _loadProgress();
              _loadGoals();
              setState(() {});
              await _maybeShowContinueReminder();
            }
          },
        ),
      ),
    );
  }

  Future<void> _maybeShowContinueReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('tpl_continue_last');
    if (ts != null && DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)).inHours < 24) {
      return;
    }
    for (final t in _templates) {
      final street = t.targetStreet;
      if (street == null || t.streetGoal <= 0) continue;
      final val = _streetProgress[t.id];
      if (val == null) continue;
      final ratio = val / t.streetGoal;
      if (ratio >= 0.5 && ratio < 1.0 && !t.goalAchieved) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(days: 1),
            content: Text('${_streetName(street)} почти закрыт в ${t.name} — доиграем?'),
            action: SnackBarAction(
              label: 'Продолжить',
              onPressed: () async {
                await _showStreetProgress(t);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPackPlayScreen(template: t, original: t),
                  ),
                );
                if (mounted) {
                  await _loadProgress();
                  _loadGoals();
                  setState(() {});
                  await _maybeShowContinueReminder();
                }
              },
            ),
          ),
        );
        await prefs.setInt('tpl_continue_last', DateTime.now().millisecondsSinceEpoch);
        break;
      }
    }
  }

  Future<void> _loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    for (final t in _templates) {
      t.goalAchieved = prefs.getBool('tpl_goal_${t.id}') ?? false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadHideCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hideCompleted = prefs.getBool(_prefsHideKey) ?? false);
    }
  }

  Future<void> _loadGroupByStreet() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _groupByStreet = prefs.getBool(_prefsGroupKey) ?? false);
    }
  }

  Future<void> _loadGroupByType() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _groupByType = prefs.getBool(_prefsTypeKey) ?? false);
    }
  }

  Future<void> _loadMixedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _mixedHandGoalOnly = prefs.getBool(_prefsMixedHandKey) ?? false;
        _mixedCount = prefs.getInt(_prefsMixedCountKey) ?? 20;
        _mixedStreet = prefs.getString(_prefsMixedStreetKey) ?? 'any';
        _mixedAutoOnly = prefs.getBool(_prefsMixedAutoKey) ?? false;
        _endlessDrill = prefs.getBool(_prefsEndlessKey) ?? false;
        final ts = prefs.getInt('tpl_mixed_last_run');
        _mixedLastRun = ts == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ts);
      });
    }
  }

  Future<void> _setHideCompleted(bool value) async {
    setState(() => _hideCompleted = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsHideKey, value);
  }

  Future<void> _setGroupByStreet(bool value) async {
    setState(() => _groupByStreet = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsGroupKey, value);
  }

  Future<void> _setGroupByType(bool value) async {
    setState(() => _groupByType = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsTypeKey, value);
  }

  Future<void> _setMixedHandGoalOnly(bool value) async {
    setState(() => _mixedHandGoalOnly = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsMixedHandKey, value);
  }

  Future<void> _saveMixedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsMixedCountKey, _mixedCount);
    await prefs.setString(_prefsMixedStreetKey, _mixedStreet);
    await prefs.setBool(_prefsMixedAutoKey, _mixedAutoOnly);
    await prefs.setBool(_prefsEndlessKey, _endlessDrill);
    await prefs.setBool(_prefsMixedHandKey, _mixedHandGoalOnly);
  }

  Future<void> _clearMixedPrefs() async {
    setState(() {
      _mixedCount = 20;
      _mixedStreet = 'any';
      _mixedAutoOnly = false;
      _mixedHandGoalOnly = false;
      _endlessDrill = false;
    });
    await _saveMixedPrefs();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsFavoritesKey) ?? [];
    if (mounted) setState(() => _favorites.addAll(list));
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsFavoritesKey, _favorites.toList());
  }

  Future<void> _toggleFavorite(String id) async {
    setState(() {
      if (!_favorites.add(id)) {
        _favorites.remove(id);
      }
    });
    await _saveFavorites();
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

  String _streetName(String street) {
    switch (street) {
      case 'preflop':
        return 'Preflop';
      case 'flop':
        return 'Flop';
      case 'turn':
        return 'Turn';
      case 'river':
        return 'River';
      default:
        return street;
    }
  }

  String _mixedSummary() {
    final parts = <String>['${_mixedCount} spots'];
    parts.add(_mixedStreet == 'any' ? 'Any' : _streetName(_mixedStreet));
    if (_mixedHandGoalOnly) parts.add('Hand Goal only');
    if (_mixedAutoOnly) parts.add('Auto only');
    return parts.join(' • ');
  }

  List<String> _topTags(TrainingPackTemplate tpl) {
    final counts = <String, int>{};
    for (final s in tpl.spots) {
      for (final tag in s.tags) {
        final t = tag.trim();
        if (t.isEmpty) continue;
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(3)) e.key];
  }

  String _spotSummary(TrainingPackSpot s) {
    final acts = s.hand.actions[0] ?? [];
    final parts = <String>[];
    for (final a in acts) {
      if (a.action == 'board') continue;
      final label = a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
      parts.add('${label}${a.amount != null ? ' ${a.amount}' : ''}');
    }
    return parts.join(' – ');
  }

  Future<void> _showStreetProgress(TrainingPackTemplate tpl) async {
    if (tpl.targetStreet == null || tpl.streetGoal <= 0) return;
    final done = _streetProgress[tpl.id]?.clamp(0, tpl.streetGoal) ?? 0;
    final ratio = done / tpl.streetGoal;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: ratio),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, _) => SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.orangeAccent),
                ),
                Text('${(value * 100).round()}%',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (done >= tpl.streetGoal) {
      final prefs = await SharedPreferences.getInstance();
      final key = 'tpl_sgoal_${tpl.id}_${tpl.streetGoal}';
      if (!(prefs.getBool(key) ?? false)) {
        await prefs.setBool(key, true);
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            content: Text(
              '🏆 Goal achieved on ${_streetName(tpl.targetStreet!)}! Great job!',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  bool _isIcmTemplate(TrainingPackTemplate t) {
    if (t.meta['icmType'] != null) return true;
    if (t.spots.isEmpty) return false;
    for (final s in t.spots) {
      if (!s.tags.contains('icm')) return false;
    }
    return true;
  }

  List<TrainingPackTemplate> _visibleTemplates() {
    final byType = _selectedType == null
        ? _templates
        : [for (final t in _templates) if (t.gameType == _selectedType) t];
    final filtered = _selectedTag == null
        ? byType
        : [for (final t in byType) if (t.tags.contains(_selectedTag)) t];
    final icmFiltered = !_icmOnly
        ? filtered
        : [for (final t in filtered) if (_isIcmTemplate(t)) t];
    final evalFiltered = !_showNeedsEvalOnly
        ? icmFiltered
        : [
            for (final t in icmFiltered)
              if (t.evCovered < t.spots.length ||
                  t.icmCovered < t.spots.length)
                t
          ];
    final completed = _completedOnly
        ? [for (final t in evalFiltered) if (t.goalAchieved) t]
        : evalFiltered;
    final visible = _hideCompleted
        ? [
            for (final t in completed)
              if ((t.spots.isEmpty
                      ? 0.0
                      : (_progress[t.id] ?? 0) / t.spots.length) < 1.0 ||
                  !t.goalAchieved)
                t
          ]
        : completed;
    return [
      for (final t in visible)
        if ((_query.isEmpty || t.name.toLowerCase().contains(_query)) &&
            (_tagFilters.isEmpty ||
                t.tags.any((tag) => _tagFilters.contains(tag))))
          t
    ];
  }

  void _scheduleAutoEval() {
    if (_autoEvalQueued) return;
    _autoEvalQueued = true;
    _autoEvalTimer?.cancel();
    _autoEvalTimer = Timer(const Duration(milliseconds: 400), () async {
      await _autoUpdateEval();
      _autoEvalQueued = false;
    });
  }

  Future<void> _autoUpdateEval() async {
    if (_autoEvalRunning || OfflineEvaluatorService.isOffline || !mounted) return;
    _autoEvalRunning = true;
    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      final list = [
        for (final t in _visibleTemplates())
          if (t.evCovered < t.spots.length || t.icmCovered < t.spots.length) t
      ];
      var refreshed = 0;
      for (final t in list) {
        final n = await BulkEvaluatorService()
            .generateMissingForTemplate(t)
            .catchError((_) => 0);
        if (!mounted) return;
        TemplateCoverageUtils.recountAll(t);
        refreshed += n;
        setState(() {});
      }
      if (refreshed > 0) {
        await TrainingPackStorage.save(_templates);
        if (!mounted) return;
        messenger?.showSnackBar(
          SnackBar(content: Text('EV/ICM refreshed for $refreshed spot${refreshed == 1 ? '' : 's'}')),
        );
      }
      if (mounted) setState(() {});
    } finally {
      _autoEvalRunning = false;
    }
  }

  TrainingPackTemplate? _suggestTemplate([String? street]) {
    final list = <TrainingPackTemplate>[];
    for (final t in _templates) {
      final s = t.targetStreet;
      if (s == null || t.spots.isEmpty) continue;
      if (street != null && s != street) continue;
      list.add(t);
    }
    if (list.isEmpty) return null;
    if (street != null) {
      TrainingPackTemplate? result;
      double ratio = 2;
      for (final t in list) {
        final total = t.spots.length;
        if (total == 0) continue;
        final r = (_progress[t.id]?.clamp(0, total) ?? 0) / total;
        if (r < ratio) {
          ratio = r;
          result = t;
        }
      }
      return result;
    }
    street = (() {
      final byStreet = <String, List<TrainingPackTemplate>>{};
      for (final t in list) {
        byStreet.putIfAbsent(t.targetStreet!, () => []).add(t);
      }
      String? st;
      double best = 2;
      for (final e in byStreet.entries) {
        double sum = 0;
        for (final t in e.value) {
          final total = t.spots.length;
          if (total == 0) continue;
          sum += (_progress[t.id]?.clamp(0, total) ?? 0) / total;
        }
        final avg = sum / e.value.length;
        if (avg < best) {
          best = avg;
          st = e.key;
        }
      }
      return best >= 0.999 ? null : st;
    })();
    if (street == null) return null;
    TrainingPackTemplate? result;
    double ratio = 2;
    for (final t in list) {
      if (t.targetStreet != street) continue;
      final total = t.spots.length;
      if (total == 0) continue;
      final r = (_progress[t.id]?.clamp(0, total) ?? 0) / total;
      if (r < ratio) {
        ratio = r;
        result = t;
      }
    }
    return result;
  }

  Widget _buildTemplateTile(TrainingPackTemplate t, bool narrow,
      {int? index}) {
    final total = t.spots.length;
    final allEv = total > 0 && t.evCovered >= total;
    final allIcm = total > 0 && t.icmCovered >= total;
    final needsEval = total > 0 && (t.evCovered < total || t.icmCovered < total);
    final isNew = t.lastGeneratedAt != null &&
        DateTime.now().difference(t.lastGeneratedAt!).inHours < 48;
    final header = ListTile(
      tileColor:
          t.id == _lastOpenedId ? Theme.of(context).highlightColor : null,
      title: Row(
        children: [
          if (needsEval)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.warning, color: Colors.amber, size: 16),
            ),
          if (t.streetGoal > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: (_streetProgress[t.id]?.clamp(0, t.streetGoal) ?? 0) /
                      t.streetGoal,
                  strokeWidth: 3,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.orangeAccent),
                ),
              ),
            ),
          if (t.focusHandTypes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  value: (() {
                    final totals = _handGoalTotal[t.id] ?? {};
                    final progress = _handGoalProgress[t.id] ?? {};
                    final total = totals.values.fold<int>(0, (a, b) => a + b);
                    final done = progress.entries
                        .fold<int>(0, (a, e) => a + e.value.clamp(0, totals[e.key] ?? 0));
                    return total > 0 ? done / total : 0.0;
                  })(),
                  strokeWidth: 3,
                  backgroundColor: Colors.white24,
                  valueColor:
                      const AlwaysStoppedAnimation(Colors.purpleAccent),
                ),
              ),
            ),
          Expanded(child: Text(t.name)),
          if (isNew)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Chip(
                label: Text('NEW', style: TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (t.isDraft)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Chip(
                label: Text('DRAFT', style: TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.grey,
              ),
            ),
          if (allIcm)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Chip(
                label: Text('ICM', style: TextStyle(fontSize: 12)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          if (allEv)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('📈', style: TextStyle(fontSize: 16)),
            ),
          if (t.goalAchieved)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text('🏆', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
      subtitle: (() {
        final items = <Widget>[];
        final pos = t.posRangeLabel();
        if (pos.isNotEmpty) {
          items.add(Text(pos,
              style: const TextStyle(fontSize: 12, color: Colors.white70)));
          items.add(const SizedBox(height: 4));
        }
        final progVal =
            total > 0 ? (_progress[t.id]?.clamp(0, total) ?? 0) / total : 0.0;
        final progColor = t.goalAchieved ? Colors.green : Colors.orange;
        items.add(LinearProgressIndicator(
          value: progVal,
          color: progColor,
          backgroundColor: progColor.withOpacity(0.3),
        ));
        items.add(const SizedBox(height: 4));
        if (t.targetStreet != null && t.streetGoal > 0) {
          final val =
              (_streetProgress[t.id]?.clamp(0, t.streetGoal) ?? 0) / t.streetGoal;
          items.add(Row(
            children: [
              Expanded(child: LinearProgressIndicator(value: val)),
              const SizedBox(width: 8),
              Text('${(val * 100).round()}%',
                  style: const TextStyle(fontSize: 12)),
            ],
          ));
          items.add(const SizedBox(height: 4));
        }
        if (t.focusHandTypes.isNotEmpty) {
          final totals = _handGoalTotal[t.id] ?? {};
          final progress = _handGoalProgress[t.id] ?? {};
          for (final g in t.focusHandTypes) {
            final total = totals[g.label] ?? 0;
            if (total > 0) {
              final done = progress[g.label]?.clamp(0, total) ?? 0;
              final val = done / total;
              items.add(Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: val,
                      color: Colors.purpleAccent,
                      backgroundColor:
                          Colors.purpleAccent.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${g.label} ${(val * 100).round()}%',
                      style: const TextStyle(fontSize: 12)),
                ],
              ));
              items.add(const SizedBox(height: 4));
            }
          }
        }
        final ratio = t.goalTarget > 0
            ? (t.goalProgress / t.goalTarget).clamp(0.0, 1.0)
            : 0.0;
        if (t.goalTarget > 0) {
          items.add(Row(
            children: [
              Expanded(child: LinearProgressIndicator(value: ratio)),
              const SizedBox(width: 8),
              Text('${(ratio * 100).round()}%',
                  style: const TextStyle(fontSize: 12)),
            ],
          ));
        }
        final prog = _progress[t.id];
        if (prog != null) {
          items.add(Text(
            '${prog.clamp(0, total)}/$total done',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ));
        }
        if (t.description.trim().isNotEmpty) {
          items.add(Text(
            t.description.split('\n').first,
            style: const TextStyle(fontSize: 12),
          ));
        }
        final tags = _topTags(t);
        if (tags.isNotEmpty) {
          items.add(Text(
            'Tags: ${tags.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ));
        }
        if (t.focusTags.isNotEmpty) {
          items.add(Text(
            '🎯 Focus: ${t.focusTags.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ));
        }
        if (t.focusHandTypes.isNotEmpty) {
          items.add(Text(
            '🃏 Hand Goal: ${t.focusHandTypes.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ));
        }
        if (t.lastGeneratedAt != null) {
          items.add(Text(
            'Last generated: ${timeago.format(t.lastGeneratedAt!)}',
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ));
        }
        if (items.isEmpty) return null;
        if (items.length == 1) return items.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items,
        );
      })(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (t.targetStreet != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                t.streetGoal > 0
                    ? '${_streetName(t.targetStreet!)} Goal: ${t.streetGoal}%'
                    : '${_streetName(t.targetStreet!)} Focus',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Start training',
            onPressed: () async {
              await _showStreetProgress(t);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TrainingPackPlayScreen(template: t, original: t),
                ),
              );
              if (mounted) {
                await _loadProgress();
                _loadGoals();
                setState(() {});
                await _maybeShowContinueReminder();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Generate spots',
            onPressed: () async {
              final service = TrainingPackTemplateUiService();
              final generated =
                  await service.generateSpotsWithProgress(context, t);
              if (!mounted) return;
              setState(() => t.spots.addAll(generated));
              TrainingPackStorage.save(_templates);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rename') _rename(t);
              if (v == 'duplicate') _duplicate(t);
              if (v == 'missing') _generateMissing(t);
              if (v == 'delete') _delete(t);
              if (v == 'quick') {
                final spots = List<TrainingPackSpot>.from(t.spots)..shuffle();
                final quick = t.copyWith(
                  id: const Uuid().v4(),
                  name: 'Quick Drill: ${t.name}',
                  spots: spots.take(5).toList(),
                  targetStreet: null,
                  streetGoal: 0,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingPackPlayScreen(template: quick, original: t),
                  ),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'quick',
                child: Text('Quick Drill (5 spots)'),
              ),
              PopupMenuItem(
                value: 'rename',
                child: Text('✏️ Rename'),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: Text('📄 Duplicate'),
              ),
              PopupMenuItem(
                value: 'missing',
                child: Text('Generate Missing'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('🗑️ Delete'),
              ),
            ],
          ),
          if (narrow)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(t),
            )
          else
            TextButton(
              onPressed: () => _edit(t),
              child: const Text('📝 Edit'),
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _duplicate(t),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _delete(t),
          ),
        ],
      ),
    );
    final children = [
      for (final s in t.spots)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            dense: true,
            title: Text(
              '${s.hand.position.label} ${s.hand.heroCards}',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              _spotSummary(s),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
    ];
    final tile = GestureDetector(
      onLongPress: () => _duplicate(t),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: header,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _favorites.contains(t.id) ? Icons.star : Icons.star_border,
              ),
              color:
                  _favorites.contains(t.id) ? Colors.amber : Colors.white54,
              onPressed: () => _toggleFavorite(t.id),
            ),
            if (t.targetStreet != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  t.streetGoal > 0
                      ? '${_streetName(t.targetStreet!)} Goal: ${t.streetGoal}%'
                      : '${_streetName(t.targetStreet!)} Focus',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Start training',
              onPressed: () async {
                await _showStreetProgress(t);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingPackPlayScreen(template: t, original: t),
                  ),
                );
                if (mounted) {
                  await _loadProgress();
                  _loadGoals();
                  setState(() {});
                  await _maybeShowContinueReminder();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.auto_fix_high),
              tooltip: 'Generate spots',
              onPressed: () async {
                final service = TrainingPackTemplateUiService();
                final generated =
                    await service.generateSpotsWithProgress(context, t);
                if (!mounted) return;
                setState(() => t.spots.addAll(generated));
                TrainingPackStorage.save(_templates);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rename') _rename(t);
                if (v == 'duplicate') _duplicate(t);
                if (v == 'missing') _generateMissing(t);
                if (v == 'delete') _delete(t);
                if (v == 'quick') {
                  final spots = List<TrainingPackSpot>.from(t.spots)..shuffle();
                  final quick = t.copyWith(
                    id: const Uuid().v4(),
                    name: 'Quick Drill: ${t.name}',
                    spots: spots.take(5).toList(),
                    targetStreet: null,
                    streetGoal: 0,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TrainingPackPlayScreen(template: quick, original: t),
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'quick',
                  child: Text('Quick Drill (5 spots)'),
                ),
                PopupMenuItem(
                  value: 'rename',
                  child: Text('✏️ Rename'),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Text('📄 Duplicate'),
                ),
                PopupMenuItem(
                  value: 'missing',
                  child: Text('Generate Missing'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('🗑️ Delete'),
                ),
              ],
            ),
            if (narrow)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _edit(t),
              )
            else
              TextButton(
                onPressed: () => _edit(t),
                child: const Text('📝 Edit'),
              ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _duplicate(t),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _delete(t),
            ),
          ],
        ),
        children: children,
      ),
    );
    if (index == null) return tile;
    return Container(
      key: ValueKey(t.id),
      child: Row(
        children: [
          if (!_loading)
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          Expanded(child: tile),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _loading = true;
    TrainingPackStorage.load().then((list) async {
      if (!mounted) return;
      setState(() {
        _templates.addAll(list);
        _sortTemplates();
        _loading = false;
      });
      await _loadProgress();
      _loadGoals();
      setState(() {});
      _loadHideCompleted();
      _loadMixedPrefs();
      _loadGroupByStreet();
      _loadGroupByType();
      _loadFavorites();
    });
    GeneratedPackHistoryService.load().then((list) {
      if (!mounted) return;
      setState(() => _history = list);
    });
  }

  void _edit(TrainingPackTemplate template) async {
    await _showStreetProgress(template);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackTemplateEditorScreen(
          template: template,
          templates: _templates,
        ),
      ),
    );
    setState(() {});
    TrainingPackStorage.save(_templates);
  }

  Future<void> _rename(TrainingPackTemplate template) async {
    final ctrl = TextEditingController(text: template.name);
    GameType type = template.gameType;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit template'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GameType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Game Type'),
                items: const [
                  DropdownMenuItem(
                      value: GameType.tournament, child: Text('Tournament')),
                  DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
                ],
                onChanged: (v) =>
                    setState(() => type = v ?? GameType.tournament),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          template.name = name;
          template.gameType = type;
        });
        TrainingPackStorage.save(_templates);
      }
    }
  }

  void _duplicate(TrainingPackTemplate template) {
    final index = _templates.indexOf(template);
    if (index == -1) return;
    final copy = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: '${template.name} (copy)',
      description: template.description,
      tags: List<String>.from(template.tags),
      spots: [
        for (final s in template.spots)
          s.copyWith(
            id: const Uuid().v4(),
            hand: HandData.fromJson(s.hand.toJson()),
            tags: List<String>.from(s.tags),
          )
      ],
      createdAt: DateTime.now(),
    );
    setState(() {
      _templates.insert(index + 1, copy);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
  }

  Future<void> _generateMissing(TrainingPackTemplate t) async {
    final service = TrainingPackTemplateUiService();
    final missing = await service.generateMissingSpotsWithProgress(context, t);
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All spots already present 🎉')));
      return;
    }
    setState(() => t.spots.addAll(missing));
    TrainingPackStorage.save(_templates);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added ${missing.length} spots')));
  }

  Future<void> _delete(TrainingPackTemplate t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete pack?'),
        content: Text('“${t.name}” will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      final idx = _templates.indexOf(t);
      setState(() {
        _lastRemoved = t;
        _lastIndex = idx;
        _templates.removeAt(idx);
        _favorites.remove(t.id);
      });
      TrainingPackStorage.save(_templates);
      _saveFavorites();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Deleted'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              if (_lastRemoved != null) {
                setState(() => _templates.insert(_lastIndex, _lastRemoved!));
                TrainingPackStorage.save(_templates);
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _nameAndEdit(TrainingPackTemplate template) async {
    final ctrl = TextEditingController(text: template.name);
    final streetCtrl =
        TextEditingController(text: template.streetGoal > 0 ? '${template.streetGoal}' : '');
    GameType type = template.gameType;
    String street = template.targetStreet ?? 'any';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Pack Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrl, autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<GameType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Game Type'),
                items: const [
                  DropdownMenuItem(
                      value: GameType.tournament,
                      child: Text('Tournament')),
                  DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
                ],
                onChanged: (v) =>
                    setState(() => type = v ?? GameType.tournament),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: street,
                decoration: const InputDecoration(labelText: 'Target Street'),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'flop', child: Text('Flop')),
                  DropdownMenuItem(value: 'turn', child: Text('Turn')),
                  DropdownMenuItem(value: 'river', child: Text('River')),
                ],
                onChanged: (v) => setState(() => street = v ?? 'any'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: streetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Street Goal (optional)',
                  helperText: 'Напр., 50',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      final name = ctrl.text.trim();
      if (name.isNotEmpty) {
        setState(() {
          template.name = name;
          template.gameType = type;
          template.targetStreet = street == 'any' ? null : street;
          template.streetGoal = int.tryParse(streetCtrl.text) ?? 0;
          _sortTemplates();
        });
        TrainingPackStorage.save(_templates);
      }
    }
    ctrl.dispose();
    streetCtrl.dispose();
    _edit(template);
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    GameType type = GameType.tournament;
    String street = 'any';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Pack'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<GameType>(
                value: type,
                decoration: const InputDecoration(labelText: 'Game Type'),
                items: const [
                  DropdownMenuItem(value: GameType.tournament, child: Text('Tournament')),
                  DropdownMenuItem(value: GameType.cash, child: Text('Cash')),
                ],
                onChanged: (v) => setState(() => type = v ?? GameType.tournament),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: street,
                decoration: const InputDecoration(labelText: 'Target Street'),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'flop', child: Text('Flop')),
                  DropdownMenuItem(value: 'turn', child: Text('Turn')),
                  DropdownMenuItem(value: 'river', child: Text('River')),
                ],
                onChanged: (v) => setState(() => street = v ?? 'any'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: streetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Street Goal (optional)',
                  helperText: 'Напр., 50',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      nameCtrl.dispose();
      streetCtrl.dispose();
      return;
    }
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: nameCtrl.text.trim().isEmpty ? 'New Pack' : nameCtrl.text.trim(),
      gameType: type,
      targetStreet: street == 'any' ? null : street,
      streetGoal: int.tryParse(streetCtrl.text) ?? 0,
      createdAt: DateTime.now(),
    );
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'mistakes',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    nameCtrl.dispose();
    streetCtrl.dispose();
    _edit(template);
  }

  Future<void> _quickGenerate() async {
    final template = await PackGeneratorService.generatePushFoldPack(
      id: const Uuid().v4(),
      name: 'Standard Pack',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: PackGeneratorService.topNHands(25).toList(),
      createdAt: DateTime.now(),
    );
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'quick',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    _nameAndEdit(template);
  }

  Future<void> _generateFinalTable() async {
    final streetCtrl = TextEditingController();
    String street = 'any';
    String savedGoal = '';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Final Table Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: street,
                decoration: const InputDecoration(labelText: 'Target Street'),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'flop', child: Text('Flop')),
                  DropdownMenuItem(value: 'turn', child: Text('Turn')),
                  DropdownMenuItem(value: 'river', child: Text('River')),
                ],
                onChanged: (v) {
                  final s = v ?? 'any';
                  if (s == 'any') {
                    savedGoal = streetCtrl.text;
                    streetCtrl.clear();
                  } else if (street == 'any') {
                    streetCtrl.text = savedGoal;
                  }
                  setState(() => street = s);
                },
              ),
              TextField(
                controller: streetCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Street Goal (optional)'),
                enabled: street != 'any',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) {
      streetCtrl.dispose();
      return;
    }
    await Future.delayed(Duration.zero);
    final template =
        PackGeneratorService.generateFinalTablePack(createdAt: DateTime.now())
            .copyWith(id: const Uuid().v4());
    template.targetStreet = street == 'any' ? null : street;
    template.streetGoal = int.tryParse(streetCtrl.text) ?? 0;
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'final',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    streetCtrl.dispose();
    _nameAndEdit(template);
  }


  HeroPosition _posFromString(String s) {
    final p = s.toUpperCase();
    if (p.startsWith('SB')) return HeroPosition.sb;
    if (p.startsWith('BB')) return HeroPosition.bb;
    if (p.startsWith('BTN')) return HeroPosition.btn;
    if (p.startsWith('CO')) return HeroPosition.co;
    if (p.startsWith('MP') || p.startsWith('HJ')) return HeroPosition.mp;
    if (p.startsWith('UTG')) return HeroPosition.utg;
    return HeroPosition.unknown;
  }

  TrainingPackSpot _spotFromHand(SavedHand hand) {
    final heroCards = hand.playerCards[hand.heroIndex]
        .map((c) => '${c.rank}${c.suit}')
        .join(' ');
    final actions = <ActionEntry>[for (final a in hand.actions) if (a.street == 0) a];
    for (final a in actions) {
      if (a.playerIndex == hand.heroIndex) {
        a.ev = hand.evLoss ?? 0;
        break;
      }
    }
    final stacks = <String, double>{
      for (int i = 0; i < hand.numberOfPlayers; i++)
        '$i': (hand.stackSizes[i] ?? 0).toDouble()
    };
    return TrainingPackSpot(
      id: const Uuid().v4(),
      hand: HandData(
        heroCards: heroCards,
        position: _posFromString(hand.heroPosition),
        heroIndex: hand.heroIndex,
        playerCount: hand.numberOfPlayers,
        stacks: stacks,
        actions: {0: actions},
      ),
      tags: List<String>.from(hand.tags),
    );
  }

  Future<void> _generateFavorites() async {
    final storage = context.read<TrainingSpotStorageService>();
    final spots = await storage.load();
    final hands = <String>{};
    for (final s in spots) {
      if (!s.tags.contains('favorite')) continue;
      if (s.playerCards.length <= s.heroIndex || s.playerCards[s.heroIndex].length < 2) continue;
      final c = s.playerCards[s.heroIndex];
      final cards = '${c[0].rank}${c[0].suit} ${c[1].rank}${c[1].suit}';
      final code = handCode(cards);
      if (code != null) hands.add(code);
    }
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No favorites found')));
      }
      return;
    }
    final list = hands.toList()
      ..sort((a, b) => PackGeneratorService.handRanking.indexOf(a).compareTo(
          PackGeneratorService.handRanking.indexOf(b)));
    final template = await PackGeneratorService.generatePushFoldPack(
      id: const Uuid().v4(),
      name: 'Favorites',
      heroBbStack: 10,
      playerStacksBb: const [10, 10],
      heroPos: HeroPosition.sb,
      heroRange: list,
      createdAt: DateTime.now(),
    );
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    await GeneratedPackHistoryService.logPack(
      id: template.id,
      name: template.name,
      type: 'fav',
      ts: DateTime.now(),
    );
    _history = await GeneratedPackHistoryService.load();
    if (mounted) setState(() {});
    _nameAndEdit(template);
  }

  Future<void> _generateTopMistakes() async {
    final manager = context.read<SavedHandManagerService>();
    final hands = manager.hands
        .where((h) => h.evLoss != null)
        .toList()
      ..sort((a, b) => (a.evLoss ?? 0).compareTo(b.evLoss ?? 0));
    if (hands.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('No history')));
      }
      return;
    }
    final seen = <String>{};
    final spots = <TrainingPackSpot>[];
    for (final h in hands) {
      if (seen.add(h.id)) spots.add(_spotFromHand(h));
      if (spots.length == 10) break;
    }
    if (spots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Недостаточно данных')));
      }
      return;
    }
    final template = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Top ${spots.length} Mistakes',
      createdAt: DateTime.now(),
      spots: spots,
    );
    template.tags.add('auto');
    setState(() {
      _templates.add(template);
      _sortTemplates();
    });
    TrainingPackStorage.save(_templates);
    _edit(template);
  }

  Future<void> _pasteRange() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Range'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Hands'),
          maxLines: null,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final range = PackGeneratorService.parseRangeString(ctrl.text).toList();
      if (range.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid hands found.')),
        );
      } else {
        final template = await PackGeneratorService.generatePushFoldPack(
          id: const Uuid().v4(),
          name: 'Pasted Range',
          heroBbStack: 10,
          playerStacksBb: const [10, 10],
          heroPos: HeroPosition.sb,
          heroRange: range,
          createdAt: DateTime.now(),
        );
        template.tags.add('auto');
        setState(() {
          _templates.add(template);
          _sortTemplates();
        });
        TrainingPackStorage.save(_templates);
        await GeneratedPackHistoryService.logPack(
          id: template.id,
          name: template.name,
          type: 'paste',
          ts: DateTime.now(),
        );
        _history = await GeneratedPackHistoryService.load();
        if (mounted) setState(() {});
        _nameAndEdit(template);
      }
    }
    ctrl.dispose();
  }

  Future<void> _generate() async {
    final nameCtrl = TextEditingController();
    final heroStackCtrl = TextEditingController(text: '10');
    final playerStacksCtrl = TextEditingController(text: '10,10');
    final rangeCtrl = TextEditingController();
    final streetGoalCtrl = TextEditingController();
    String street = 'any';
    final selected = <String>{};
    double percent = 0;
    double bbCall = 20;
    HeroPosition pos = HeroPosition.sb;
    bool listenerAdded = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          if (!listenerAdded) {
            listenerAdded = true;
            rangeCtrl.addListener(() {
              selected
                ..clear()
                ..addAll(PackGeneratorService.parseRangeString(rangeCtrl.text));
              percent = selected.length / 169 * 100;
              setState(() {});
            });
          }
          final parsed = selected.toList()..sort();
          return AlertDialog(
            title: const Text('Generate Pack'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: heroStackCtrl,
                    decoration: const InputDecoration(labelText: 'Hero Stack'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: playerStacksCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Stacks (e.g. 10/8/20)',
                    ),
                  ),
                  DropdownButtonFormField<HeroPosition>(
                    value: pos,
                    decoration:
                        const InputDecoration(labelText: 'Hero Position'),
                    items: [
                      for (final p in HeroPosition.values)
                        DropdownMenuItem(value: p, child: Text(p.label)),
                    ],
                    onChanged: (v) =>
                        setState(() => pos = v ?? HeroPosition.sb),
                  ),
                  DropdownButtonFormField<String>(
                    value: street,
                    decoration:
                        const InputDecoration(labelText: 'Target Street'),
                    items: const [
                      DropdownMenuItem(value: 'any', child: Text('Any')),
                      DropdownMenuItem(value: 'flop', child: Text('Flop')),
                      DropdownMenuItem(value: 'turn', child: Text('Turn')),
                      DropdownMenuItem(value: 'river', child: Text('River')),
                    ],
                    onChanged: (v) => setState(() => street = v ?? 'any'),
                  ),
                  TextField(
                    controller: streetGoalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                        labelText: 'Street Goal (optional)'),
                  ),
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        const TabBar(tabs: [
                          Tab(text: 'Text'),
                          Tab(text: 'Matrix'),
                          Tab(text: 'Presets')
                        ]),
                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            children: [
                              TextField(
                                controller: rangeCtrl,
                                decoration:
                                    const InputDecoration(labelText: 'Range'),
                                maxLines: null,
                              ),
                              SingleChildScrollView(
                                child: RangeMatrixPicker(
                                  selected: selected,
                                  onChanged: (v) {
                                    selected
                                      ..clear()
                                      ..addAll(v);
                                    rangeCtrl.text =
                                        PackGeneratorService.serializeRange(v);
                                    percent = selected.length / 169 * 100;
                                  },
                                ),
                              ),
                              Column(
                                children: [
                                  PresetRangeButtons(
                                    selected: selected,
                                    onChanged: (v) {
                                      selected
                                        ..clear()
                                        ..addAll(v);
                                      rangeCtrl.text =
                                          PackGeneratorService.serializeRange(
                                              v);
                                      percent = selected.length / 169 * 100;
                                      setState(() {});
                                    },
                                  ),
                                  Slider(
                                    value: percent,
                                    min: 0,
                                    max: 100,
                                    onChanged: (v) {
                                      percent = v;
                                      selected
                                        ..clear()
                                        ..addAll(PackGeneratorService.topNHands(
                                            v.round()));
                                      rangeCtrl.text =
                                          PackGeneratorService.serializeRange(
                                              selected);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('BB call ${bbCall.round()}%'),
                  Slider(
                    value: bbCall,
                    min: 0,
                    max: 100,
                    onChanged: (v) => setState(() => bbCall = v),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'In SB vs BB, hands from top ${bbCall.round()}% will trigger a call instead of fold. This affects action preview, not EV.',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: parsed.isEmpty
                          ? [const Text('No hands yet')]
                          : [for (final h in parsed) Text('[$h]')],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Выбрано: ${selected.length} рук (${((selected.length / 169) * 100).round()} %)\nTop-N: ${percent.round()} %'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
    if (ok == true) {
      final name =
          nameCtrl.text.trim().isEmpty ? 'New Pack' : nameCtrl.text.trim();
      final hero = int.tryParse(heroStackCtrl.text.trim()) ?? 0;
      final stacks = [
        for (final s in playerStacksCtrl.text.split(RegExp(r'[,/]+')))
          if (s.trim().isNotEmpty) int.tryParse(s.trim()) ?? hero
      ];
      if (stacks.isEmpty) stacks.add(hero);
      final range = selected.toList();
      final template = await PackGeneratorService.generatePushFoldPack(
        id: const Uuid().v4(),
        name: name,
        heroBbStack: hero,
        playerStacksBb: stacks,
        heroPos: pos,
        heroRange: range,
        bbCallPct: bbCall.round(),
        createdAt: DateTime.now(),
      );
      template.targetStreet = street == 'any' ? null : street;
      template.streetGoal = int.tryParse(streetGoalCtrl.text) ?? 0;
      template.tags.add('auto');
      setState(() {
        _templates.add(template);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      await GeneratedPackHistoryService.logPack(
        id: template.id,
        name: template.name,
        type: 'custom',
        ts: DateTime.now(),
      );
      _history = await GeneratedPackHistoryService.load();
      if (mounted) setState(() {});
      _edit(template);
    }
    nameCtrl.dispose();
    heroStackCtrl.dispose();
    playerStacksCtrl.dispose();
    rangeCtrl.dispose();
    streetGoalCtrl.dispose();
  }

  Future<void> _export() async {
    final json = jsonEncode([
      for (final t in _templates)
        if (!t.isDraft) t.toJson()
    ]);
    await Clipboard.setData(ClipboardData(text: json));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Templates copied to clipboard')),
    );
  }

  Future<void> _import() async {
    final clip = await Clipboard.getData('text/plain');
    if (clip?.text == null || clip!.text!.trim().isEmpty) return;
    List? raw;
    try {
      raw = jsonDecode(clip.text!);
    } catch (_) {}
    if (raw is! List) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid JSON')));
      return;
    }
    final imported = [
      for (final m in raw)
        TrainingPackTemplate.fromJson(Map<String, dynamic>.from(m))
    ];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Import templates?'),
        content:
            Text('This will add ${imported.length} template(s) to your list.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Import')),
        ],
      ),
    );
    if (ok ?? false) {
      setState(() {
        _templates.addAll(imported);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} template(s) imported')),
      );
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final data = file.bytes != null
        ? String.fromCharCodes(file.bytes!)
        : await File(file.path!).readAsString();
    final allRows = const CsvToListConverter().convert(data.trim());
    try {
      final tpl = PackImportService.importFromCsv(
        csv: data,
        templateId: const Uuid().v4(),
        templateName: p.basenameWithoutExtension(file.name),
      );
      final skipped = allRows.length - 1 - tpl.spots.length;
      setState(() {
        _templates.add(tpl);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${tpl.spots.length} spots' +
              (skipped > 0 ? ', $skipped skipped' : '')),
        ),
      );
      _edit(tpl);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid CSV')));
    }
  }

  Future<void> _pasteCsv() async {
    final clip = await Clipboard.getData('text/plain');
    final text = clip?.text?.trim();
    if (text == null || !text.startsWith('Title,HeroPosition')) return;
    final rows = const CsvToListConverter().convert(text);
    try {
      final tpl = PackImportService.importFromCsv(
        csv: text,
        templateId: const Uuid().v4(),
        templateName: 'Pasted Pack',
      );
      final skipped = rows.length - 1 - tpl.spots.length;
      setState(() {
        _templates.add(tpl);
        _sortTemplates();
      });
      TrainingPackStorage.save(_templates);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${tpl.spots.length} spots' +
              (skipped > 0 ? ', $skipped skipped' : '')),
        ),
      );
      _edit(tpl);
    } catch (_) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invalid CSV')));
    }
  }

  Future<void> _generateMissingEvIcmAll() async {
    final list = [
      for (final t in _templates)
        if (t.evCovered < t.spots.length || t.icmCovered < t.spots.length) t
    ];
    if (list.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing to update')));
      return;
    }
    double progress = 0;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var started = false;
        return StatefulBuilder(
          builder: (context, setDialog) {
            if (!started) {
              started = true;
              Future.microtask(() async {
                for (var i = 0; i < list.length; i++) {
                  final tpl = list[i];
                  await BulkEvaluatorService().generateMissingForTemplate(
                    tpl,
                    (p) {
                      progress = (i + p) / list.length;
                      if (mounted) setDialog(() {});
                    },
                  );
                  TemplateCoverageUtils.recountAll(tpl);
                  if (mounted) setState(() {});
                }
                await TrainingPackStorage.save(_templates);
                if (Navigator.canPop(ctx)) Navigator.pop(ctx);
              });
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 12),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (mounted) setState(() {});
  }

  void _showFilters() {
    final tags = <String>{for (final t in _templates) ...t.tags};
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedType == null,
                onSelected: (_) => setState(() => _selectedType = null),
              ),
              ChoiceChip(
                label: const Text('Tournament'),
                selected: _selectedType == GameType.tournament,
                onSelected: (_) =>
                    setState(() => _selectedType = GameType.tournament),
              ),
              ChoiceChip(
                label: const Text('Cash'),
                selected: _selectedType == GameType.cash,
                onSelected: (_) =>
                    setState(() => _selectedType = GameType.cash),
              ),
              ChoiceChip(
                label: const Text('🏆 Completed'),
                selected: _completedOnly,
                onSelected: (_) =>
                    setState(() => _completedOnly = !_completedOnly),
              ),
              ChoiceChip(
                label: const Text('ICM Only'),
                selected: _icmOnly,
                onSelected: (_) => setState(() => _icmOnly = !_icmOnly),
              ),
              if (tags.isNotEmpty) ...[
                ChoiceChip(
                  label: const Text('All Tags'),
                  selected: _selectedTag == null,
                  onSelected: (_) => setState(() => _selectedTag = null),
                ),
                for (final tag in tags)
                  ChoiceChip(
                    label: Text(tag),
                    selected: _selectedTag == tag,
                    onSelected: (_) => setState(() => _selectedTag = tag),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startMixedDrill() async {
    final byType = _selectedType == null
        ? _templates
        : [for (final t in _templates) if (t.gameType == _selectedType) t];
    final filtered = _selectedTag == null
        ? byType
        : [for (final t in byType) if (t.tags.contains(_selectedTag)) t];
    final icmFiltered = !_icmOnly
        ? filtered
        : [for (final t in filtered) if (_isIcmTemplate(t)) t];
    final completed = _completedOnly
        ? [for (final t in icmFiltered) if (t.goalAchieved) t]
        : icmFiltered;
    final visible = _hideCompleted
        ? [
            for (final t in completed)
              if ((t.spots.isEmpty
                      ? 0.0
                      : (_progress[t.id] ?? 0) / t.spots.length) < 1.0 ||
                  !t.goalAchieved)
                t
          ]
        : completed;
    final shown = _query.isEmpty
        ? visible
        : [
            for (final t in visible)
              if (t.name.toLowerCase().contains(_query) ||
                  t.description.toLowerCase().contains(_query))
                t
          ];
    final hasFocus = shown.any((t) => t.focusHandTypes.isNotEmpty);
    final countCtrl = TextEditingController(text: _mixedCount.toString());
    bool autoOnly = _mixedAutoOnly;
    bool endless = _endlessDrill;
    String street = _mixedStreet;
    bool handOnly = _mixedHandGoalOnly;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mixed Drill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: countCtrl,
                decoration: const InputDecoration(labelText: 'Spots count'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<String>(
                value: street,
                onChanged: (v) => setState(() => street = v ?? 'any'),
                items: const [
                  DropdownMenuItem(value: 'any', child: Text('Any')),
                  DropdownMenuItem(value: 'preflop', child: Text('Preflop')),
                  DropdownMenuItem(value: 'flop', child: Text('Flop')),
                  DropdownMenuItem(value: 'turn', child: Text('Turn')),
                  DropdownMenuItem(value: 'river', child: Text('River')),
                ],
              ),
              CheckboxListTile(
                value: autoOnly,
                onChanged: (v) => setState(() => autoOnly = v ?? false),
                title: const Text('Only auto-generated'),
              ),
              CheckboxListTile(
                value: endless,
                onChanged: (v) => setState(() => endless = v ?? false),
                title: const Text('Endless Drill'),
              ),
              CheckboxListTile(
                value: handOnly,
                onChanged:
                    hasFocus ? (v) => setState(() => handOnly = v ?? false) : null,
                enabled: hasFocus,
                title: const Text('Hand Goal only'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    setState(() {
      _mixedCount = int.tryParse(countCtrl.text.trim()) ?? 0;
      _mixedAutoOnly = autoOnly;
      _endlessDrill = endless;
      _mixedStreet = street;
      _mixedHandGoalOnly = handOnly;
    });
    await _saveMixedPrefs();
    await _runMixedDrill();
  }

  Future<void> _runMixedDrill() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tpl_mixed_last_run', now.millisecondsSinceEpoch);
    setState(() => _mixedLastRun = now);
    final count = _mixedCount;
    final autoOnly = _mixedAutoOnly;
    final byType = _selectedType == null
        ? _templates
        : [for (final t in _templates) if (t.gameType == _selectedType) t];
    final filtered = _selectedTag == null
        ? byType
        : [for (final t in byType) if (t.tags.contains(_selectedTag)) t];
    final completed = _completedOnly
        ? [for (final t in filtered) if (t.goalAchieved) t]
        : filtered;
    final visible = _hideCompleted
        ? [
            for (final t in completed)
              if ((t.spots.isEmpty
                      ? 0.0
                      : (_progress[t.id] ?? 0) / t.spots.length) < 1.0 ||
                  !t.goalAchieved)
                t
          ]
        : completed;
    final shown = _query.isEmpty
        ? visible
        : [
            for (final t in visible)
              if (t.name.toLowerCase().contains(_query) ||
                  t.description.toLowerCase().contains(_query))
                t
          ];
    final list =
        autoOnly ? [for (final t in shown) if (t.tags.contains('auto')) t] : shown;
    final spots = <TrainingPackSpot>[];
    for (final t in list) {
      for (final s in t.spots) {
        if (_mixedStreet != 'any') {
          final idx = {
            'preflop': 0,
            'flop': 3,
            'turn': 4,
            'river': 5
          }[_mixedStreet];
          if (idx != s.hand.board.length) continue;
        }
        if (_mixedHandGoalOnly && t.focusHandTypes.isNotEmpty) {
          final code = handCode(s.hand.heroCards);
          if (code == null) continue;
          var ok = false;
          for (final label in t.focusHandTypes) {
            if (matchHandTypeLabel(label, code)) {
              ok = true;
              break;
            }
          }
          if (!ok) continue;
        }
        spots.add(s);
      }
    }
    if (spots.isEmpty) {
      if (mounted) await _startMixedDrill();
      return;
    }
    spots.shuffle(Random());
    final picked =
        count <= 0 || spots.length <= count ? spots : spots.take(count).toList();
    final tpl = TrainingPackTemplate(
      id: 'mixed_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Mixed Drill',
      tags: const ['mixed', 'auto'],
      spots: picked,
      createdAt: DateTime.now(),
    );
    await GeneratedPackHistoryService.logPack(
      id: tpl.id,
      name: tpl.name,
      type: 'mixed',
      ts: DateTime.now(),
    );
    if (!mounted) return;
    await _openTrainingSession(
      tpl,
      persist: false,
      onSessionEnd: _endlessDrill ? _runMixedDrill : null,
    );
    final service = context.read<TrainingSessionService>();
    if (service.session?.completedAt != null) {
      final hist = context.read<MixedDrillHistoryService>();
      await hist.add(
        MixedDrillStat(
          date: DateTime.now(),
          total: service.totalCount,
          correct: service.correctCount,
          tags: [
            if (_selectedTag != null) _selectedTag!,
            if (autoOnly && (_selectedTag != 'auto')) 'auto'
          ],
          street: _mixedStreet,
        ),
      );
    }
  }

  Future<void> _openTrainingSession(
    TrainingPackTemplate template, {
    bool persist = true,
    VoidCallback? onSessionEnd,
  }) async {
    await context
        .read<TrainingSessionService>()
        .startSession(template, persist: persist);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingSessionScreen(onSessionEnd: onSessionEnd),
      ),
    );
    if (!mounted) return;
    setState(() => _lastOpenedId = template.id);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _lastOpenedId != template.id) return;
      setState(() => _lastOpenedId = null);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filtersShown && MediaQuery.of(context).size.width < 400) {
      _filtersShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showFilters());
    }
    _scheduleAutoEval();
  }

  @override
  void dispose() {
    _autoEvalTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 400;
    final tagCounts = <String, int>{};
    for (final t in _templates) {
      for (final tag in t.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.keys.toList()
      ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));
    final tags = topTags.take(10).toList();
    final base = _showFavoritesOnly
        ? [for (final t in _templates) if (_favorites.contains(t.id)) t]
        : _templates;
    final byType = _selectedType == null
        ? base
        : [for (final t in base) if (t.gameType == _selectedType) t];
    final filtered = _selectedTag == null
        ? byType
        : [
            for (final t in byType)
              if (t.tags.contains(_selectedTag)) t
          ];
    final icmFiltered = !_icmOnly
        ? filtered
        : [
            for (final t in filtered)
              if (_isIcmTemplate(t)) t
          ];
    final evalFiltered = !_showNeedsEvalOnly
        ? icmFiltered
        : [
            for (final t in icmFiltered)
              if (t.evCovered < t.spots.length ||
                  t.icmCovered < t.spots.length)
                t
          ];
    final completed = _completedOnly
        ? [for (final t in evalFiltered) if (t.goalAchieved) t]
        : evalFiltered;
    final visible = _hideCompleted
        ? [
            for (final t in completed)
              if ((t.spots.isEmpty
                      ? 0.0
                      : (_progress[t.id] ?? 0) / t.spots.length) < 1.0 ||
                  !t.goalAchieved)
                t
          ]
        : completed;
    final shown = [
      for (final t in visible)
        if ((_query.isEmpty || t.name.toLowerCase().contains(_query)) &&
            (_tagFilters.isEmpty ||
                t.tags.any((tag) => _tagFilters.contains(tag))))
          t
    ];
    final streetGroups = <String, List<TrainingPackTemplate>>{};
    if (_groupByStreet) {
      for (final t in shown) {
        final key = t.targetStreet ?? 'any';
        streetGroups.putIfAbsent(key, () => []).add(t);
      }
    } else {
      streetGroups['all'] = shown;
    }
    final history = _dedupHistory();
    final suggestion = _groupByStreet ? _suggestTemplate() : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Packs'),
        actions: [
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
            icon: Icon(
              _showFavoritesOnly ? Icons.star : Icons.star_border,
              color: _showFavoritesOnly ? Colors.amber : null,
            ),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
          ),
          IconButton(
            icon: Icon(
              Icons.auto_fix_high,
              color: _showNeedsEvalOnly ? Colors.amber : null,
            ),
            tooltip: 'Needs EV/ICM',
            onPressed: () => setState(() => _showNeedsEvalOnly = !_showNeedsEvalOnly),
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            tooltip: 'Import',
            onPressed: _import,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _export,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) {
              setState(() {
                _sort = v;
                _sortTemplates();
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name', child: Text('Name A–Z')),
              PopupMenuItem(value: 'created', child: Text('Newest First')),
              PopupMenuItem(value: 'last_trained', child: Text('Last Trained')),
              PopupMenuItem(value: 'spots', child: Text('Most Spots')),
              PopupMenuItem(value: 'tag', child: Text('Tag A–Z')),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'paste') _pasteCsv();
              if (v == 'calc_ev_icm') _generateMissingEvIcmAll();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'paste', child: Text('Paste CSV')),
              PopupMenuItem(
                value: 'calc_ev_icm',
                child: Text('Generate Missing EV/ICM for All'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight * 2),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _query = '';
                            }),
                          ),
                  ),
                  onChanged: (v) =>
                      setState(() => _query = v.trim().toLowerCase()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final tag in tags)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(tag),
                            selected: _tagFilters.contains(tag),
                            onSelected: (_) => setState(() {
                              if (_tagFilters.contains(tag)) {
                                _tagFilters.remove(tag);
                              } else {
                                _tagFilters.add(tag);
                              }
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Builder(builder: (context) {
                  final stats = context.watch<MixedDrillHistoryService>().stats;
                  if (stats.isEmpty) return const SizedBox.shrink();
                  final s = stats.first;
                  final tags = s.tags.isEmpty ? '-' : s.tags.join(', ');
                  final pct = s.accuracy.toStringAsFixed(1);
                  return ListTile(
                    title: const Text('Last Mixed Drill'),
                    subtitle: Text('$pct% • ${s.street} • $tags'),
                  );
                }),
                if (history.isNotEmpty)
                  ExpansionTile(
                    title: const Text('Recent Generated Packs'),
                    children: [
                      for (final h in history)
                        ListTile(
                          tileColor: h.id == _lastOpenedId
                              ? Theme.of(context).highlightColor
                              : null,
                          title: Text(h.name),
                          subtitle: Text(
                              '${h.type} • ${DateFormat.yMMMd().add_Hm().format(h.ts)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Start training',
                            onPressed: () {
                              final tpl =
                                  _templates.firstWhereOrNull((t) => t.id == h.id);
                              if (tpl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pack not found')));
                                return;
                              }
                              await _showStreetProgress(tpl);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrainingPackPlayScreen(
                                      template: tpl, original: tpl),
                                ),
                              );
                              if (mounted) {
                                await _loadProgress();
                                _loadGoals();
                                setState(() {});
                                await _maybeShowContinueReminder();
                              }
                            },
                          ),
                          onTap: () {
                            final tpl =
                                _templates.firstWhereOrNull((t) => t.id == h.id);
                            if (tpl != null) {
                              _edit(tpl);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Pack not found')));
                            }
                          },
                        ),
                    ],
                  ),
                if (suggestion != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insights, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _streetLabel(suggestion.targetStreet),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(suggestion.name,
                                  style: const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await _showStreetProgress(suggestion);
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrainingPackPlayScreen(
                                    template: suggestion, original: suggestion),
                              ),
                            );
                            if (mounted) {
                              await _loadProgress();
                              _loadGoals();
                              setState(() {});
                              await _maybeShowContinueReminder();
                            }
                          },
                          child: const Text('Start Training'),
                        ),
                      ],
                    ),
                  ),
                SwitchListTile(
                  title: const Text('Hide Completed'),
                  value: _hideCompleted,
                  onChanged: _setHideCompleted,
                  activeColor: Colors.orange,
                ),
                SwitchListTile(
                  title: const Text('Group by Street'),
                  value: _groupByStreet,
                  onChanged: _setGroupByStreet,
                  activeColor: Colors.orange,
                ),
                SwitchListTile(
                  title: const Text('Group by Game Type'),
                  value: _groupByType,
                  onChanged: _setGroupByType,
                  activeColor: Colors.orange,
                ),
                if (!narrow)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedType == null,
                          onSelected: (_) =>
                              setState(() => _selectedType = null),
                        ),
                        ChoiceChip(
                          label: const Text('Tournament'),
                          selected: _selectedType == GameType.tournament,
                          onSelected: (_) => setState(
                              () => _selectedType = GameType.tournament),
                        ),
                        ChoiceChip(
                          label: const Text('Cash'),
                          selected: _selectedType == GameType.cash,
                          onSelected: (_) =>
                              setState(() => _selectedType = GameType.cash),
                        ),
                        ChoiceChip(
                          label: const Text('🏆 Completed'),
                          selected: _completedOnly,
                          onSelected: (_) =>
                              setState(() => _completedOnly = !_completedOnly),
                        ),
                        ChoiceChip(
                          label: const Text('ICM Only'),
                          selected: _icmOnly,
                          onSelected: (_) =>
                              setState(() => _icmOnly = !_icmOnly),
                        ),
                        if (tags.isNotEmpty) ...[
                          ChoiceChip(
                            label: const Text('All Tags'),
                            selected: _selectedTag == null,
                            onSelected: (_) =>
                                setState(() => _selectedTag = null),
                          ),
                          for (final tag in tags)
                            ChoiceChip(
                              label: Text(tag),
                              selected: _selectedTag == tag,
                              onSelected: (_) =>
                                  setState(() => _selectedTag = tag),
                            ),
                        ],
                      ],
                    ),
                  ),
                Expanded(
                  child: (_groupByStreet || _groupByType)
                      ? ListView(
                          children: [
                            for (final street in [
                              if (_groupByStreet) ...[
                                'preflop',
                                'flop',
                                'turn',
                                'river',
                                'any'
                              ]
                              else
                                'all'
                            ])
                              if (streetGroups[street]?.isNotEmpty ?? false) ...[
                                if (_groupByStreet)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text(
                                      _streetLabel(street == 'all' ? null : street),
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                if (_groupByType)
                                  for (final type in GameType.values)
                                    if (streetGroups[street]!
                                        .where((t) => t.gameType == type)
                                        .isNotEmpty) ...[
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: _groupByStreet ? 32 : 16,
                                            vertical: 4),
                                        child: Text(
                                          type == GameType.tournament
                                              ? 'Tournament Packs'
                                              : 'Cash Game Packs',
                                          style:
                                              Theme.of(context).textTheme.titleSmall,
                                        ),
                                      ),
                                      for (final t in streetGroups[street]!
                                          .where((e) => e.gameType == type))
                                        _buildTemplateTile(t, narrow),
                                    ]
                                else
                                  for (final t in streetGroups[street]!)
                                    _buildTemplateTile(t, narrow),
                              ]
                          ],
                        )
                      : ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: shown.length,
                          onReorder: (oldIndex, newIndex) {
                            final item = shown[oldIndex];
                            final oldPos = _templates.indexOf(item);
                            int newPos;
                            if (newIndex >= shown.length) {
                              newPos = _templates.length;
                            } else {
                              newPos = _templates.indexOf(shown[newIndex]);
                            }
                            setState(() {
                              _templates.removeAt(oldPos);
                              _templates.insert(
                                newPos > oldPos ? newPos - 1 : newPos,
                                item,
                              );
                            });
                            TrainingPackStorage.save(_templates);
                          },
                          itemBuilder: (context, index) {
                            final t = shown[index];
                            return _buildTemplateTile(t, narrow, index: index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (narrow)
            FloatingActionButton(
              heroTag: 'filterTplFab',
              onPressed: _showFilters,
              child: const Icon(Icons.filter_list),
            ),
          if (narrow) const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'quickGenTplFab',
            onPressed: _quickGenerate,
            label: const Text('Quick Generate'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'finalTableTplFab',
            onPressed: () => _generateFinalTable(),
            tooltip: 'Generate Final Table Pack',
            label: const Text('Final Table'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'favoritesTplFab',
            onPressed: _generateFavorites,
            icon: const Icon(Icons.star),
            label: const Text('Favorites Pack'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'topMistakesTplFab',
            onPressed: _generateTopMistakes,
            tooltip: 'Generate Top Mistakes Pack',
            label: const Text('Top 10 Mistakes'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'reviewMistakesTplFab',
            icon: const Icon(Icons.error),
            label: const Text('Review Mistakes'),
            onPressed: () async {
              final tpl =
                  await MistakeReviewPackService.latestTemplate(context);
              if (!mounted) return;
              if (tpl != null && tpl.spots.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        TrainingPackPlayScreen(template: tpl, original: tpl),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No mistakes to review')),
                );
              }
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'mixedDrillFab',
            icon: const Icon(Icons.shuffle),
            label: const Text('Mixed Drill'),
            tooltip: 'Mixed Drill (tap to edit, long press to restart)',
            onPressed: _startMixedDrill,
            onLongPress: _runMixedDrill,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: _runMixedDrill,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text.rich(
                      TextSpan(text: _mixedSummary()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear',
                  onPressed: _clearMixedPrefs,
                ),
              ],
            ),
          ),
          if (_mixedLastRun != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Last run: ${timeago.format(_mixedLastRun!)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'pasteRangeTplFab',
            onPressed: _pasteRange,
            icon: const Icon(Icons.content_paste),
            label: const Text('Paste Range'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'genTplFab',
            onPressed: _generate,
            label: const Text('➕ Generate Pack'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'importCsvTplFab',
            onPressed: _importCsv,
            child: const Icon(Icons.upload_file),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'addTplFab',
            onPressed: _add,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
