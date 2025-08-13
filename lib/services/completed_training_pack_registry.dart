import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_fingerprint_generator.dart';

/// Persists completed training packs keyed by their deterministic fingerprints.
///
/// Each entry stores the original YAML along with completion metadata so that
/// sessions can be reconstructed and progress analyzed.
class CompletedTrainingPackRegistry {
  CompletedTrainingPackRegistry({
    SharedPreferences? prefs,
    TrainingPackFingerprintGenerator? fingerprintGenerator,
  })  : _prefs = prefs,
        _fingerprintGenerator =
            fingerprintGenerator ?? const TrainingPackFingerprintGenerator();

  SharedPreferences? _prefs;
  final TrainingPackFingerprintGenerator _fingerprintGenerator;

  static const _prefix = 'completed_pack_';

  Future<SharedPreferences> get _sp async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Stores [pack] as a completed training pack, capturing its YAML and
  /// metadata such as completion timestamp, training type and accuracy.
  Future<void> storeCompletedPack(
    TrainingPackTemplateV2 pack, {
    DateTime? completedAt,
    double? accuracy,
    Duration? duration,
  }) async {
    final prefs = await _sp;
    final fingerprint = _fingerprintGenerator.generateFromTemplate(pack);
    final data = <String, dynamic>{
      'yaml': pack.toYamlString(),
      'timestamp': (completedAt ?? DateTime.now()).toIso8601String(),
      'type': pack.trainingType.name,
      if (accuracy != null) 'accuracy': accuracy,
      if (duration != null) 'durationMs': duration.inMilliseconds,
    };
    await prefs.setString('$_prefix$fingerprint', jsonEncode(data));
  }

  /// Returns stored data for [fingerprint] or `null` if absent.
  Future<Map<String, dynamic>?> getCompletedPackData(String fingerprint) async {
    final prefs = await _sp;
    final raw = prefs.getString('$_prefix$fingerprint');
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    return null;
  }

  /// Lists fingerprints of all completed packs persisted in the registry.
  Future<List<String>> listCompletedFingerprints() async {
    final prefs = await _sp;
    final list = <String>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        list.add(key.substring(_prefix.length));
      }
    }
    return list;
  }

  /// Deletes the stored data for [fingerprint] if it exists.
  Future<void> deleteCompletedPack(String fingerprint) async {
    final prefs = await _sp;
    await prefs.remove('$_prefix$fingerprint');
  }
}
