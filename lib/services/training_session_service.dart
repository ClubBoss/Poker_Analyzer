import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_session.dart';

class TrainingSessionService extends ChangeNotifier {
  Box<dynamic>? _box;
  Box<dynamic>? _activeBox;
  TrainingSession? _session;
  List<TrainingPackSpot> _spots = [];
  Timer? _timer;

  TrainingSession? get session => _session;
  Duration get elapsedTime => _session == null
      ? Duration.zero
      : (_session!.completedAt ?? DateTime.now())
          .difference(_session!.startedAt);

  TrainingPackSpot? get currentSpot =>
      _session != null && _session!.index < _spots.length
          ? _spots[_session!.index]
          : null;

  Map<String, bool> get results => _session?.results ?? {};
  int get correctCount => results.values.where((e) => e).length;
  int get totalCount => results.length;

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
    final raw = _activeBox!.get('session');
    if (raw is Map) {
      final data = Map<String, dynamic>.from(raw);
      final s = data['session'];
      final spots = data['spots'];
      if (s is Map) {
        final session =
            TrainingSession.fromJson(Map<String, dynamic>.from(s));
        if (session.completedAt == null) {
          _session = session;
          _timer = Timer.periodic(
            const Duration(seconds: 1),
            (_) => notifyListeners(),
          );
          _spots = [
            for (final e in (spots as List? ?? []))
              TrainingPackSpot.fromJson(Map<String, dynamic>.from(e))
          ];
        } else {
          _activeBox!.delete('session');
        }
      }
    }
    notifyListeners();
  }

  void _saveActive() {
    if (_session == null) return;
    if (_session!.completedAt != null) {
      _activeBox?.delete('session');
    } else {
      _activeBox?.put('session', {
        'session': _session!.toJson(),
        'spots': [for (final s in _spots) s.toJson()]
      });
    }
  }

  Future<void> startSession(TrainingPackTemplate template) async {
    await _openBox();
    _spots = List<TrainingPackSpot>.from(template.spots);
    _session = TrainingSession(
      id: const Uuid().v4(),
      templateId: template.id,
    );
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
    await _box!.put(_session!.id, _session!.toJson());
    _saveActive();
    notifyListeners();
  }

  Future<void> submitResult(String spotId, bool isCorrect) async {
    if (_session == null) return;
    _session!.results[spotId] = isCorrect;
    await _box!.put(_session!.id, _session!.toJson());
    _saveActive();
  }

  TrainingPackSpot? nextSpot() {
    if (_session == null) return null;
    _session!.index += 1;
    if (_session!.index >= _spots.length) {
      _session!.completedAt = DateTime.now();
      _timer?.cancel();
    }
    _box?.put(_session!.id, _session!.toJson());
    _saveActive();
    notifyListeners();
    return currentSpot;
  }

  TrainingPackSpot? prevSpot() {
    if (_session == null) return null;
    if (_session!.index > 0) {
      _session!.index -= 1;
      _box?.put(_session!.id, _session!.toJson());
      _saveActive();
      notifyListeners();
    }
    return currentSpot;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
