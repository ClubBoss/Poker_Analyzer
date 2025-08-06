import 'dart:io';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'spot_fingerprint_generator.dart';

/// Keeps track of spot fingerprints to automatically skip duplicates.
class AutoDeduplicationEngine {
  final SpotFingerprintGenerator _fingerprint;
  final Set<String> _seen = <String>{};
  final IOSink _log;
  int _skipped = 0;

  AutoDeduplicationEngine({
    SpotFingerprintGenerator? fingerprint,
    IOSink? log,
  })  : _fingerprint = fingerprint ?? const SpotFingerprintGenerator(),
        _log = log ?? File('skipped_duplicates.log').openWrite(mode: FileMode.append);

  /// Registers existing spots so future checks can detect duplicates.
  void addExisting(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      _seen.add(_fingerprint.generate(s));
    }
  }

  /// Returns `true` if [spot] is a duplicate and logs the skip.
  bool isDuplicate(TrainingPackSpot spot, {String? source}) {
    final fp = _fingerprint.generate(spot);
    if (_seen.contains(fp)) {
      _skipped++;
      _log.writeln('Skipped duplicate from ${source ?? 'unknown'}: ${spot.id}');
      return true;
    }
    _seen.add(fp);
    return false;
  }

  /// Deduplicates [original] by removing spots with matching fingerprints.
  ///
  /// The first occurrence of each unique fingerprint is kept while subsequent
  /// duplicates are discarded. Returns a new [TrainingPackModel] containing only
  /// the unique spots. The internal fingerprint registry is updated with all
  /// retained spots so subsequent calls can detect cross-pack duplicates.
  TrainingPackModel deduplicate(TrainingPackModel original) {
    final unique = <TrainingPackSpot>[];
    for (final spot in original.spots) {
      final fp = _fingerprint.generate(spot);
      if (_seen.contains(fp)) {
        _skipped++;
        _log.writeln('Skipped duplicate from ${original.id}: ${spot.id}');
        continue;
      }
      _seen.add(fp);
      unique.add(spot);
    }
    return TrainingPackModel(
      id: original.id,
      title: original.title,
      spots: unique,
      tags: List<String>.from(original.tags),
      metadata: Map<String, dynamic>.from(original.metadata),
    );
  }

  int get skippedCount => _skipped;

  /// Closes the underlying log sink.
  Future<void> dispose() => _log.close();
}
