import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/v2/training_pack_spot.dart';
import 'evaluation_settings_service.dart';

class RemoteEvService {
  final String endpoint;
  final http.Client client;
  const RemoteEvService({String? endpoint, http.Client? client})
      : endpoint = endpoint ?? EvaluationSettingsService.instance.remoteEndpoint,
        client = client ?? const http.Client();

  Future<void> evaluate(TrainingPackSpot spot, {int anteBb = 0}) async {
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
      }
    } catch (_) {}
  }

  Future<void> evaluateIcm(TrainingPackSpot spot, {int anteBb = 0}) async {
    try {
      final res = await client.post(
        Uri.parse(endpoint),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'hand': spot.hand.toJson(), 'anteBb': anteBb, 'icm': true}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final ev = (data['ev'] as num?)?.toDouble();
        final icm = (data['icm'] as num?)?.toDouble();
        _apply(spot, ev: ev, icm: icm);
      }
    } catch (_) {}
  }

  void _apply(TrainingPackSpot spot, {double? ev, double? icm}) {
    final hero = spot.hand.heroIndex;
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == hero && a.action == 'push') {
        if (ev != null) a.ev = ev;
        if (icm != null) a.icmEv = icm;
        break;
      }
    }
  }
}
