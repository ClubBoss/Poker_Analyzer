import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../helpers/hand_utils.dart';
import '../helpers/hand_type_utils.dart';
import '../helpers/training_pack_storage.dart';
import '../screens/training_session_summary_screen.dart';
import 'mistake_review_pack_service.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_session.dart';
import '../models/v2/training_action.dart';
import '../models/v2/focus_goal.dart';

class TrainingSessionService extends ChangeNotifier {
  Box<dynamic>? _box;
  Box<dynamic>? _activeBox;
  TrainingSession? _session;
  TrainingPackTemplate? _template;
  List<TrainingPackSpot> _spots = [];
  final List<TrainingAction> _actions = [];
  Timer? _timer;
  bool _paused = false;
  DateTime? _resumedAt;
  Duration _accumulated = Duration.zero;
  final List<FocusGoal> _focusHandTypes = [];
  final Map<String, int> _handGoalTotal = {};
  final Map<String, int> _handGoalCount = {};
  double _preEvPct = 0;
  double _preIcmPct = 0;

  double get preEvPct => _preEvPct;
  double get preIcmPct => _preIcmPct;

  bool get isPaused => _paused;
  List<FocusGoal> get focusHandTypes => List.unmodifiable(_focusHandTypes);
  Map<String, int> get handGoalTotal => Map.unmodifiable(_handGoalTotal);
  Map<String, int> get handGoalCount => Map.unmodifiable(_handGoalCount);

  TrainingSession? get currentSession => _session;
  bool get isCompleted => _session?.completedAt != null;

  void _startTicker() {
    _timer?.cancel();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  TrainingSession? get session => _session;
  Duration get elapsedTime {
    if (_session == null) return Duration.zero;
    var d = _accumulated;
    if (!_paused && _resumedAt != null) {
      d += (_session!.completedAt ?? DateTime.now()).difference(_resumedAt!);
    }
    return d;
  }

  TrainingPackSpot? get currentSpot =>
      _session != null && _session!.index < _spots.length
          ? _spots[_session!.index]
          : null;

  Map<String, bool> get results => _session?.results ?? {};
  int get correctCount => results.values.where((e) => e).length;
  int get totalCount => results.length;
  List<TrainingAction> get actionLog => List.unmodifiable(_actions);
  List<TrainingPackSpot> get spots => List.unmodifiable(_spots);
  TrainingPackTemplate? get template => _template;

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('sessions');
    } else {
      _box = Hive.box('sessions');
    }
    if (!Hive.isBoxOpen('active_session')) {
      _activeBox = await Hive.openBox('active_session');
    } else {
      _activeBox = Hive.box('active_session');
    }
  }

  Future<void> load() async {
    await _openBox();
    _actions.clear();
    final raw = _activeBox!.get('session');
    if (raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final s = data['session'];
      final spots = data['spots'];
      final actions = data['actions'];
      if (s is Map) {
        final session = TrainingSession.fromJson(Map<String, dynamic>.from(s));
        if (session.completedAt == null) {
          _session = session;
          try {
            final templates = await TrainingPackStorage.load();
            _template = templates.firstWhere(
              (t) => t.id == session.templateId,
              orElse: () => TrainingPackTemplate(id: '', name: ''),
            );
            if (_template!.id.isEmpty) _template = null;
          } catch (_) {
            _template = null;
          }
          _paused = false;
          _accumulated = Duration.zero;
          _resumedAt = DateTime.now();
          _startTicker();
          _spots = [
            for (final e in (spots as List? ?? []))
              TrainingPackSpot.fromJson(Map<String, dynamic>.from(e))
          ];
          _focusHandTypes
            ..clear()
            ..addAll([
              for (final t in (data['focusHandTypes'] as List? ?? []))
                FocusGoal.fromJson(t)
            ]);
          final totalRaw = data['handGoalTotal'];
          if (totalRaw is Map) {
            _handGoalTotal
              ..clear()
              ..addAll(totalRaw.map((k, v) => MapEntry(k as String, (v as num).toInt())));
          } else if (totalRaw is int && _focusHandTypes.isNotEmpty) {
            _handGoalTotal[_focusHandTypes.first.label] = totalRaw;
          }
          final countRaw = data['handGoalProgress'];
          if (countRaw is Map) {
            _handGoalCount
              ..clear()
              ..addAll(countRaw.map((k, v) => MapEntry(k as String, (v as num).toInt())));
          } else if (countRaw is int && _focusHandTypes.isNotEmpty) {
            _handGoalCount[_focusHandTypes.first.label] = countRaw;
          }
          if (_focusHandTypes.isNotEmpty && _handGoalTotal.isEmpty) {
            for (final g in _focusHandTypes) {
              _handGoalTotal[g.label] =
                  _spots.where((s) => _matchHandTypeLabel(s, g.label)).length;
            }
          }
          if (_focusHandTypes.isNotEmpty && _handGoalCount.isEmpty) {
            for (final id in _session!.results.keys) {
              final s = _spots.firstWhere((e) => e.id == id, orElse: () => TrainingPackSpot(id: ''));
              if (s.id.isEmpty) continue;
              for (final g in _focusHandTypes) {
                if (_matchHandTypeLabel(s, g.label)) {
                  _handGoalCount[g.label] = (_handGoalCount[g.label] ?? 0) + 1;
                }
              }
            }
          }
          _actions
            ..clear()
            ..addAll([
              for (final a in (actions as List? ?? []))
                TrainingAction.fromJson(Map<String, dynamic>.from(a))
            ]);
        } else {
          _activeBox!.delete('session');
        }
      }
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _timer?.cancel();
    _session = null;
    _template = null;
    _spots.clear();
    _actions.clear();
    _focusHandTypes.clear();
    _handGoalTotal.clear();
    _handGoalCount.clear();
    if (_activeBox != null) await _activeBox!.delete('session');
    notifyListeners();
  }

  void _saveActive() {
    if (_session == null || _activeBox == null || _session!.authorPreview) return;
    if (_session!.completedAt != null) {
      _activeBox!.delete('session');
    } else {
      _activeBox!.put('session', {
        'session': _session!.toJson(),
        'spots': [for (final s in _spots) s.toJson()],
        'actions': [for (final a in _actions) a.toJson()],
        if (_focusHandTypes.isNotEmpty)
          'focusHandTypes': [for (final g in _focusHandTypes) g.toString()],
        if (_handGoalTotal.isNotEmpty) 'handGoalTotal': _handGoalTotal,
        if (_handGoalCount.isNotEmpty) 'handGoalProgress': _handGoalCount
      });
    }
  }

  void pause() {
    if (_paused) return;
    if (_resumedAt != null) {
      _accumulated += DateTime.now().difference(_resumedAt!);
      _resumedAt = null;
    }
    _paused = true;
    _timer?.cancel();
    _saveActive();
    notifyListeners();
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _resumedAt = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  Future<void> startSession(
    TrainingPackTemplate template, {
    bool persist = true,
  }) async {
    if (persist) await _openBox();
    _template = template;
    final total = template.spots.length;
    _preEvPct = total == 0 ? 0 : template.evCovered * 100 / total;
    _preIcmPct = total == 0 ? 0 : template.icmCovered * 100 / total;
    _spots = List<TrainingPackSpot>.from(template.spots);
    _actions.clear();
    _focusHandTypes
      ..clear()
      ..addAll(template.focusHandTypes);
    _handGoalTotal.clear();
    _handGoalCount.clear();
    for (final g in _focusHandTypes) {
      _handGoalTotal[g.label] =
          _spots.where((s) => _matchHandTypeLabel(s, g.label)).length;
      _handGoalCount[g.label] = 0;
    }
    _session = TrainingSession.fromTemplate(
      template,
      authorPreview: !persist,
    );
    _paused = false;
    _accumulated = Duration.zero;
    _resumedAt = DateTime.now();
    _startTicker();
    if (persist && _box != null) {
      await _box!.put(_session!.id, _session!.toJson());
      _saveActive();
    }
    notifyListeners();
  }

  Future<TrainingSession> startFromTemplate(TrainingPackTemplate template) async {
    await startSession(template, persist: false);
    return _session!;
  }

  Future<TrainingSession> startFromMistakes() async {
    final ids = results.keys.where((k) => results[k] == false).toSet();
    final spots = _spots.where((s) => ids.contains(s.id)).toList();
    final tpl = _template!.copyWith(
      id: const Uuid().v4(),
      name: 'Retry mistakes',
      spots: spots,
    );
    return startFromTemplate(tpl);
  }

  Future<TrainingSession?> startFromPastMistakes(
      TrainingPackTemplate template) async {
    await _openBox();
    final ids = <String>{};
    for (final v in _box!.values.whereType<Map>()) {
      try {
        final s = TrainingSession.fromJson(
            Map<String, dynamic>.from(v as Map));
        if (s.templateId == template.id) {
          ids.addAll(s.results.entries
              .where((e) => e.value == false)
              .map((e) => e.key));
        }
      } catch (_) {}
    }
    final spots = [
      for (final s in template.spots)
        if (ids.contains(s.id)) TrainingPackSpot.fromJson(s.toJson())
    ];
    if (spots.isEmpty) return null;
    final tpl = template.copyWith(
      name: 'Review Mistakes',
      spots: spots,
    );
    await startSession(tpl, persist: false);
    return _session;
  }

  Future<void> complete(BuildContext context) async {
    if (_session == null || _template == null) return;
    final ids = [
      for (final e in _session!.results.entries)
        if (!e.value) e.key
    ];
    if (ids.isNotEmpty) {
      final tpl = _template!.copyWith(
        id: const Uuid().v4(),
        name: 'Review mistakes',
        spots: [for (final s in _template!.spots) if (ids.contains(s.id)) s],
      );
      MistakeReviewPackService.setLatestTemplate(tpl);
      await context.read<MistakeReviewPackService>().addPack(ids);
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingSessionSummaryScreen(
          session: _session!,
          template: _template!,
          preEvPct: _preEvPct,
          preIcmPct: _preIcmPct,
        ),
      ),
    );
  }

  Future<void> submitResult(
    String spotId,
    String action,
    bool isCorrect,
  ) async {
    if (_session == null) return;
    final first = !_session!.results.containsKey(spotId);
    _session!.results[spotId] = isCorrect;
    _actions.add(
      TrainingAction(
        spotId: spotId,
        chosenAction: action,
        isCorrect: isCorrect,
      ),
    );
    if (first && _focusHandTypes.isNotEmpty) {
      final spot = _spots.firstWhere((e) => e.id == spotId, orElse: () => TrainingPackSpot(id: ''));
      if (spot.id.isNotEmpty) {
        for (final g in _focusHandTypes) {
          if (_matchHandTypeLabel(spot, g.label)) {
            _handGoalCount[g.label] = (_handGoalCount[g.label] ?? 0) + 1;
          }
        }
      }
    }
    if (_box != null) await _box!.put(_session!.id, _session!.toJson());
    _saveActive();
  }

  TrainingPackSpot? nextSpot() {
    if (_session == null) return null;
    _session!.index += 1;
    if (_session!.index >= _spots.length) {
      _session!.completedAt = DateTime.now();
      if (!_paused && _resumedAt != null) {
        _accumulated += DateTime.now().difference(_resumedAt!);
        _resumedAt = null;
      }
      _timer?.cancel();
    }
    if (_box != null) _box!.put(_session!.id, _session!.toJson());
    _saveActive();
    notifyListeners();
    return currentSpot;
  }

  TrainingPackSpot? prevSpot() {
    if (_session == null) return null;
    if (_session!.index > 0) {
      _session!.index -= 1;
      if (_box != null) _box!.put(_session!.id, _session!.toJson());
      _saveActive();
      notifyListeners();
    }
    return currentSpot;
  }

  Future<void> updateSpot(TrainingPackSpot spot) async {
    final index = _spots.indexWhere((s) => s.id == spot.id);
    if (index == -1) return;
    _spots[index] = spot;
    if (_session != null) {
      if (_box != null) await _box!.put(_session!.id, _session!.toJson());
      _saveActive();
    }
    notifyListeners();
  }

  bool _matchHandTypeLabel(TrainingPackSpot spot, String label) {
    final code = handCode(spot.hand.heroCards);
    if (code == null) return false;
    return matchHandTypeLabel(label, code);
  }

  bool _matchHandType(TrainingPackSpot spot) {
    for (final g in _focusHandTypes) {
      if (_matchHandTypeLabel(spot, g.label)) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
