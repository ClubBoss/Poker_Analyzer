import 'dart:convert';
import 'dart:collection';

import 'package:crypto/crypto.dart';

import '../models/training_pack_model.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'spot_fingerprint_generator.dart';
import 'autogen_stats_dashboard_service.dart';

/// Generates a deterministic fingerprint for training packs.
///
/// The fingerprint is a SHA256 hash of normalized pack data including
/// identifiers, tags, key parameters and spot fingerprints. Irrelevant metadata
/// such as timestamps or UI options are ignored so identical packs always
/// produce the same fingerprint regardless of field ordering.
class TrainingPackFingerprintGenerator {
  const TrainingPackFingerprintGenerator({
    SpotFingerprintGenerator? spotFingerprint,
    AutogenStatsDashboardService? dashboard,
  })  : _spotFingerprint = spotFingerprint ?? const SpotFingerprintGenerator(),
        _dashboard = dashboard ?? AutogenStatsDashboardService();

  final SpotFingerprintGenerator _spotFingerprint;
  final AutogenStatsDashboardService _dashboard;

  /// Returns a SHA256 hash uniquely representing [model]. The fingerprint is
  /// stored in `model.metadata['fingerprint']` and recorded via the autogen
  /// dashboard.
  String generate(TrainingPackModel model) {
    final normalized = _normalizeModel(model);
    final json = jsonEncode(normalized);
    final fp = sha256.convert(utf8.encode(json)).toString();
    model.metadata['fingerprint'] = fp;
    _dashboard.recordFingerprint(fp);
    return fp;
  }

  /// Generates a fingerprint for a [TrainingPackTemplateV2]. The fingerprint is
  /// stored in `tpl.meta['fingerprint']` and recorded via the autogen dashboard.
  String generateFromTemplate(TrainingPackTemplateV2 tpl) {
    final normalized = _normalizeTemplate(tpl);
    final json = jsonEncode(normalized);
    final fp = sha256.convert(utf8.encode(json)).toString();
    tpl.meta['fingerprint'] = fp;
    _dashboard.recordFingerprint(fp);
    return fp;
  }

  Map<String, dynamic> _normalizeModel(TrainingPackModel m) {
    final meta = Map<String, dynamic>.from(m.metadata)
      ..removeWhere((k, _) => _ignoredMeta.contains(k));

    final trainingType = _stringValue(meta.remove('trainingType'));
    final gameType = _stringValue(meta.remove('gameType'));

    final spots = <String, String>{};
    for (final s in m.spots) {
      spots[s.id] = _spotFingerprint.generate(s);
    }

    final map = {
      'id': m.id,
      'tags': _sortedList(m.tags),
      'trainingType': trainingType,
      'gameType': gameType,
      'meta': meta.isEmpty ? null : _sortedMap(meta),
      'spots': _sortedMap(spots),
    };

    map.removeWhere(
      (_, v) =>
          v == null || (v is List && v.isEmpty) || (v is Map && v.isEmpty),
    );

    return _sortedMap(map);
  }

  Map<String, dynamic> _normalizeTemplate(TrainingPackTemplateV2 p) {
    final meta = Map<String, dynamic>.from(p.meta)
      ..removeWhere((k, _) => _ignoredMeta.contains(k));

    final spots = <String, String>{};
    for (final s in p.spots) {
      spots[s.id] = _spotFingerprint.generate(s);
    }

    final map = {
      'id': p.id,
      'tags': _sortedList(p.tags),
      'bb': p.bb,
      'positions': _sortedList(p.positions),
      'trainingType': p.trainingType.name,
      'gameType': p.gameType.name,
      'targetStreet': p.targetStreet,
      'requiredAccuracy': p.requiredAccuracy,
      'minHands': p.minHands,
      'unlockRules': p.unlockRules?.toJson(),
      'meta': meta.isEmpty ? null : _sortedMap(meta),
      'spots': _sortedMap(spots),
    };

    map.removeWhere(
      (_, v) =>
          v == null || (v is List && v.isEmpty) || (v is Map && v.isEmpty),
    );

    return _sortedMap(map);
  }

  Map<String, dynamic> _sortedMap(Map<String, dynamic> m) {
    final tree = SplayTreeMap<String, dynamic>();
    for (final e in m.entries) {
      final v = e.value;
      if (v is Map<String, dynamic>) {
        tree[e.key] = _sortedMap(v);
      } else if (v is List) {
        tree[e.key] = _sortedList(List.from(v));
      } else {
        tree[e.key] = v;
      }
    }
    return tree;
  }

  List _sortedList(List input) {
    final list = [...input];
    list.sort((a, b) => a.toString().compareTo(b.toString()));
    return list;
  }

  static const _ignoredMeta = {
    'ui',
    'theme',
    'createdAt',
    'updatedAt',
    'fingerprint',
  };

  String? _stringValue(dynamic v) {
    if (v == null) return null;
    if (v is Enum) return v.name;
    return v.toString();
  }
}
