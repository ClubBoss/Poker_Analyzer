import '../utils/mix_keys.dart';

const String kTargetMixKey = 'targetMix';
const String kMixToleranceKey = 'mixTolerance';
const String kMixMinTotalKey = 'mixMinTotal';

/// All accepted keys for per-key tolerance maps.
const Set<String> kPerKeyToleranceKeys = {
  kMixToleranceKey,
  'mixToleranceByKey',
  'mixToleranceMap',
  'toleranceByKey',
  'tolerancesByKey',
  'toleranceMap',
  'perKeyTolerance',
  'byKeyTol',
  'byKey',
};

/// Aliases for min total guard.
const Set<String> kMinTotalKeys = {
  kMixMinTotalKey,
  'minTotal',
  'minTotalSamples',
};

/// Parses a [double] from [v], accepting numeric strings.
double? parseDouble(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Parses an [int] from [v], accepting numeric strings.
int? parseInt(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/// Merges [raw] per-key tolerance map into [target], canonicalizing keys.
void mergeTolMap(Map<String, double> target, dynamic raw) {
  if (raw is Map) {
    raw.forEach((key, value) {
      final canon = canonicalMixKey(key.toString()) ?? key.toString();
      final d = parseDouble(value);
      if (canon.isNotEmpty && d != null) {
        target[canon] = d;
      }
    });
  }
}
