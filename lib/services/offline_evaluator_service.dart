import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/v2/training_pack_spot.dart';
import 'push_fold_ev_service.dart';
import 'remote_ev_service.dart';
import 'evaluation_settings_service.dart';

class OfflineEvaluatorService {
  OfflineEvaluatorService({
    PushFoldEvService? offline,
    RemoteEvService? remote,
  })  : offline = offline ?? const PushFoldEvService(),
        remote = remote ?? RemoteEvService();

  final PushFoldEvService offline;
  final RemoteEvService remote;
  static bool get isOffline => EvaluationSettingsService.instance.offline;
  static set isOffline(bool v) =>
      EvaluationSettingsService.instance.update(offline: v);
  Box<dynamic>? _box;

  Future<void> _open() async {
    if (!Hive.isBoxOpen('ev_cache')) {
      await Hive.initFlutter();
      _box = await Hive.openBox('ev_cache');
    } else {
      _box = Hive.box('ev_cache');
    }
  }

  Future<bool> _online() async {
    if (isOffline) return false;
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
  }

  Future<void> evaluate(TrainingPackSpot spot, {int anteBb = 0}) async {
    await _open();
    final key = '${spot.id}|$anteBb';
    final cached = (_box!.get(key) as Map?)?.cast<String, dynamic>();
    if (!await _online()) {
      if (cached != null && cached['ev'] != null) {
        final hero = spot.hand.heroIndex;
        final acts = spot.hand.actions[0] ?? [];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            a.ev = (cached['ev'] as num).toDouble();
            return;
          }
        }
      }
      await offline.evaluate(spot, anteBb: anteBb);
      return;
    }
    await remote.evaluate(spot, anteBb: anteBb);
    final ev = spot.heroEv;
    if (ev != null) {
      final map = cached ?? <String, dynamic>{};
      map['ev'] = ev;
      map['ts'] = DateTime.now().toIso8601String();
      await _box!.put(key, map);
    }
  }

  Future<void> evaluateIcm(TrainingPackSpot spot, {int anteBb = 0}) async {
    await _open();
    final key = '${spot.id}|$anteBb';
    final cached = (_box!.get(key) as Map?)?.cast<String, dynamic>();
    if (!await _online()) {
      if (cached != null && cached['icm'] != null) {
        final hero = spot.hand.heroIndex;
        final acts = spot.hand.actions[0] ?? [];
        for (final a in acts) {
          if (a.playerIndex == hero && a.action == 'push') {
            a.icmEv = (cached['icm'] as num).toDouble();
            if (cached['ev'] != null) a.ev ??= (cached['ev'] as num).toDouble();
            return;
          }
        }
      }
      await offline.evaluateIcm(spot, anteBb: anteBb);
      return;
    }
    await remote.evaluateIcm(spot, anteBb: anteBb);
    final ev = spot.heroEv;
    final icm = spot.heroIcmEv;
    if (ev != null || icm != null) {
      final map = cached ?? <String, dynamic>{};
      if (ev != null) map['ev'] = ev;
      if (icm != null) map['icm'] = icm;
      map['ts'] = DateTime.now().toIso8601String();
      await _box!.put(key, map);
    }
  }
}
