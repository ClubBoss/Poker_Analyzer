import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_session.dart';

class TrainingSessionService extends ChangeNotifier {
  Box<dynamic>? _box;
  TrainingSession? _session;
  List<TrainingPackSpot> _spots = [];

  TrainingPackSpot? get currentSpot =>
      _session != null && _session!.index < _spots.length
          ? _spots[_session!.index]
          : null;

  Future<void> _openBox() async {
    if (!Hive.isBoxOpen('sessions')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('sessions');
    } else {
      _box = Hive.box('sessions');
    }
  }

  Future<void> startSession(TrainingPackTemplate template) async {
    await _openBox();
    _spots = List<TrainingPackSpot>.from(template.spots);
    _session = TrainingSession(
      id: const Uuid().v4(),
      templateId: template.id,
    );
    await _box!.put(_session!.id, _session!.toJson());
    notifyListeners();
  }

  Future<void> submitResult(String spotId, bool isCorrect) async {
    if (_session == null) return;
    _session!.results[spotId] = isCorrect;
    await _box!.put(_session!.id, _session!.toJson());
  }

  TrainingPackSpot? nextSpot() {
    if (_session == null) return null;
    _session!.index += 1;
    if (_session!.index >= _spots.length) {
      _session!.completedAt = DateTime.now();
    }
    _box?.put(_session!.id, _session!.toJson());
    notifyListeners();
    return currentSpot;
  }
}
