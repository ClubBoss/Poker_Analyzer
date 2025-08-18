import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/v2/training_pack_spot.dart';
import 'evaluation_settings_service.dart';

class RemoteEvService {
  final String endpoint;
  final http.Client client;
  static const _boxName = 'ev_cache';
  static const _cacheAge = Duration(hours: 24);
  static Box<dynamic>? _box;

  const RemoteEvService({String? endpoint, http.Client? client})
    : endpoint = endpoint ?? EvaluationSettingsService.instance.remoteEndpoint,
      client = client ?? const http.Client();

  Future<void> _openBox() async {
    if (_box != null) return;
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } else {
      _box = Hive.box(_boxName);
    }
  }

  Future<void> evaluate(TrainingPackSpot spot, {int anteBb = 0}) async {
    await _openBox();
    final key = '${spot.id}|$anteBb';
    final cached = (_box!.get(key) as Map?)?.cast<String, dynamic>();
    final ts = DateTime.tryParse(cached?['ts'] as String? ?? '');
    if (cached != null &&
        cached['ev'] != null &&
        ts != null &&
        DateTime.now().difference(ts) < _cacheAge) {
      _apply(spot, ev: (cached['ev'] as num).toDouble());
      return;
    }
    try {
      final res = await client.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'hand': spot.hand.toJson(), 'anteBb': anteBb}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ev = (data['ev'] as num?)?.toDouble();
        _apply(spot, ev: ev);
        final map = cached ?? <String, dynamic>{};
        if (ev != null) map['ev'] = ev;
        map['ts'] = DateTime.now().toIso8601String();
        await _box!.put(key, map);
      }
    } catch (_) {}
  }

  Future<void> evaluateIcm(TrainingPackSpot spot, {int anteBb = 0}) async {
    await _openBox();
    final key = '${spot.id}|$anteBb';
    final cached = (_box!.get(key) as Map?)?.cast<String, dynamic>();
    final ts = DateTime.tryParse(cached?['ts'] as String? ?? '');
    if (cached != null &&
        cached['icm'] != null &&
        ts != null &&
        DateTime.now().difference(ts) < _cacheAge) {
      _apply(
        spot,
        ev: (cached['ev'] as num?)?.toDouble(),
        icm: (cached['icm'] as num).toDouble(),
      );
      return;
    }
    try {
      final res = await client.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'hand': spot.hand.toJson(),
          'anteBb': anteBb,
          'icm': true,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ev = (data['ev'] as num?)?.toDouble();
        final icm = (data['icm'] as num?)?.toDouble();
        _apply(spot, ev: ev, icm: icm);
        final map = cached ?? <String, dynamic>{};
        if (ev != null) map['ev'] = ev;
        if (icm != null) map['icm'] = icm;
        map['ts'] = DateTime.now().toIso8601String();
        await _box!.put(key, map);
      }
    } catch (_) {}
  }

  void _apply(TrainingPackSpot spot, {double? ev, double? icm}) {
    final hero = spot.hand.heroIndex;
    final acts = spot.hand.actions[0] ?? [];
    for (var i = 0; i < acts.length; i++) {
      final a = acts[i];
      if (a.playerIndex == hero && a.action == 'push') {
        acts[i] = a.copyWith(ev: ev ?? a.ev, icmEv: icm ?? a.icmEv);
        break;
      }
    }
  }
}
