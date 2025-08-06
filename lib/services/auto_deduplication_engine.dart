import 'dart:io';
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

  int get skippedCount => _skipped;

  /// Closes the underlying log sink.
  Future<void> dispose() => _log.close();
}
