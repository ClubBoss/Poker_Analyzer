import '../models/v2/training_pack_spot.dart';
import 'spot_fingerprint_generator.dart';
import 'training_pack_fingerprint_generator.dart';
import '../models/v2/training_pack_template_v2.dart';

/// Lightweight representation of a training pack using fingerprint hash and
/// fingerprints of individual spots.
class PackFingerprint {
  final String id;
  final String hash;
  final Set<String> spots;
  final Map<String, dynamic> meta;

  PackFingerprint({
    required this.id,
    required this.hash,
    required this.spots,
    this.meta = const {},
  });

  /// Builds a [PackFingerprint] from a template by computing the pack hash and
  /// spot fingerprints.
  factory PackFingerprint.fromTemplate(
    TrainingPackTemplateV2 tpl, {
    TrainingPackFingerprintGenerator? packFingerprint,
    SpotFingerprintGenerator? spotFingerprint,
  }) {
    final spotGen = spotFingerprint ?? const SpotFingerprintGenerator();
    final packGen = packFingerprint ?? const TrainingPackFingerprintGenerator();
    final hash = packGen.generateFromTemplate(tpl);
    final spotSet = <String>{
      for (final TrainingPackSpot s in tpl.spots) spotGen.generate(s),
    };
    return PackFingerprint(
      id: tpl.id,
      hash: hash,
      spots: spotSet,
      meta: Map<String, dynamic>.from(tpl.meta),
    );
  }
}

/// Report describing an existing pack that is similar to a newly generated
/// pack.
class PackDuplicateReport {
  final String existingPackId;
  final String reason;
  final double similarity;

  PackDuplicateReport({
    required this.existingPackId,
    required this.reason,
    required this.similarity,
  });
}

/// Compares pack fingerprints to detect duplicates or highly similar packs.
class PackFingerprintComparer {
  PackFingerprintComparer();

  /// Compares [newPack] against [existingPacks] and returns reports for any
  /// packs that are either duplicates (same hash) or have >=90% overlap in spot
  /// fingerprints.
  List<PackDuplicateReport> compare(
    PackFingerprint newPack,
    List<PackFingerprint> existingPacks,
  ) {
    final results = <PackDuplicateReport>[];
    for (final existing in existingPacks) {
      if (existing.hash == newPack.hash) {
        results.add(
          PackDuplicateReport(
            existingPackId: existing.id,
            reason: 'duplicate',
            similarity: 1.0,
          ),
        );
        continue;
      }
      final overlap = _overlap(newPack.spots, existing.spots);
      if (overlap >= 0.9) {
        results.add(
          PackDuplicateReport(
            existingPackId: existing.id,
            reason: 'high similarity',
            similarity: overlap,
          ),
        );
      }
    }
    results.sort((a, b) => b.similarity.compareTo(a.similarity));
    return results;
  }

  double _overlap(Set<String> a, Set<String> b) {
    if (a.isEmpty) return 0.0;
    final inter = a.intersection(b).length.toDouble();
    return inter / a.length;
  }
}
