import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_fingerprint_comparer.dart';

/// Result returned by [PackNoveltyGuardService.evaluate].
class PackNoveltyResult {
  final bool isDuplicate;
  final String? bestMatchId;
  final double jaccard;
  final int overlapCount;
  final List<NoveltyMatch> topSimilar;

  const PackNoveltyResult({
    required this.isDuplicate,
    this.bestMatchId,
    required this.jaccard,
    required this.overlapCount,
    this.topSimilar = const [],
  });
}

/// Describes similarity between the candidate and an existing pack.
class NoveltyMatch {
  final String packId;
  final double jaccard;
  final int overlapCount;

  const NoveltyMatch({
    required this.packId,
    required this.jaccard,
    required this.overlapCount,
  });
}

/// Guards the autogen pipeline against exporting near-duplicate packs.
class PackNoveltyGuardService {
  final PackFingerprintComparer _comparer;
  final Map<String, PackFingerprint> _cache = {};
  bool _initialized = false;

  PackNoveltyGuardService({PackFingerprintComparer? comparer})
      : _comparer = comparer ?? const PackFingerprintComparer();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await TrainingPackLibraryV2.instance.loadFromFolder();
    for (final p in TrainingPackLibraryV2.instance.packs) {
      _cache[p.id] = PackFingerprint.fromTemplate(p);
    }
    // Warm from disk snapshot if present.
    final file = File('autogen_cache/fingerprints.json');
    if (await file.exists()) {
      try {
        final raw = jsonDecode(await file.readAsString());
        if (raw is List) {
          for (final entry in raw) {
            if (entry is Map) {
              final id = entry['id']?.toString();
              final hash = entry['hash']?.toString() ?? '';
              final spots = <String>{
                for (final s in (entry['spots'] as List? ?? [])) s.toString(),
              };
              if (id != null && !_cache.containsKey(id)) {
                _cache[id] = PackFingerprint(
                  id: id,
                  hash: hash,
                  spots: spots,
                  meta: {},
                );
              }
            }
          }
        }
      } catch (_) {}
    }
    _initialized = true;
  }

  Future<PackNoveltyResult> evaluate(TrainingPackTemplateV2 candidate) async {
    await _ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final minJaccard = prefs.getDouble('novelty.minJaccard') ?? 0.6;
    final reportTopK = prefs.getInt('novelty.reportTopK') ?? 5;
    final fp = PackFingerprint.fromTemplate(candidate);
    PackFingerprint? best;
    var bestJac = 0.0;
    var bestOverlap = 0;
    final matches = <NoveltyMatch>[];
    for (final existing in _cache.values) {
      final inter = fp.spots.intersection(existing.spots).length;
      final union = fp.spots.union(existing.spots).length;
      final jac = union == 0 ? 0.0 : inter / union;
      if (jac > bestJac) {
        bestJac = jac;
        best = existing;
        bestOverlap = inter;
      }
      matches.add(
        NoveltyMatch(packId: existing.id, jaccard: jac, overlapCount: inter),
      );
    }
    matches.sort((a, b) => b.jaccard.compareTo(a.jaccard));
    final top = matches.take(reportTopK).toList();
    return PackNoveltyResult(
      isDuplicate: bestJac >= minJaccard,
      bestMatchId: best?.id,
      jaccard: bestJac,
      overlapCount: bestOverlap,
      topSimilar: top,
    );
  }

  Future<void> registerExport(TrainingPackTemplateV2 tpl) async {
    await _ensureInitialized();
    final fp = PackFingerprint.fromTemplate(tpl);
    _cache[fp.id] = fp;
    await _persist();
  }

  Future<void> _persist() async {
    final dir = Directory('autogen_cache');
    await dir.create(recursive: true);
    final file = File('${dir.path}/fingerprints.json');
    final data = [
      for (final fp in _cache.values)
        {
          'id': fp.id,
          'hash': fp.hash,
          'spots': fp.spots.toList(),
        }
    ];
    await file.writeAsString(jsonEncode(data));
  }
}

