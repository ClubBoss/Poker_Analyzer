import 'dart:convert';
import 'dart:collection';

import 'package:crypto/crypto.dart';

import '../models/v2/training_pack_template_v2.dart';

/// Generates a deterministic fingerprint for a [TrainingPackTemplateV2].
///
/// The fingerprint is a SHA256 hash of normalized pack data including
/// identifiers, tags, constraints and spot IDs. Irrelevant metadata such as
/// timestamps or UI options are ignored so identical packs always produce the
/// same fingerprint regardless of field ordering.
class TrainingPackFingerprintGenerator {
  const TrainingPackFingerprintGenerator();

  /// Returns a SHA256 hash uniquely representing [pack].
  String generate(TrainingPackTemplateV2 pack) {
    final normalized = _normalizePack(pack);
    final json = jsonEncode(normalized);
    return sha256.convert(utf8.encode(json)).toString();
  }

  Map<String, dynamic> _normalizePack(TrainingPackTemplateV2 p) {
    final meta = Map<String, dynamic>.from(p.meta)
      ..removeWhere((k, _) => _ignoredMeta.contains(k));

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
      'spots': _sortedList([for (final s in p.spots) s.id]),
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

  static const _ignoredMeta = {'ui', 'theme', 'createdAt', 'updatedAt'};
}
