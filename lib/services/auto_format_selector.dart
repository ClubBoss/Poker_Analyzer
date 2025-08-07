import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/training_run_record.dart';
import 'training_pack_auto_generator.dart';
import 'autogen_pipeline_event_logger_service.dart';

/// Automatically applies the A/B recommended pack format to autogen runs.
class AutoFormatSelector {
  static const _recommendedKey = 'ab.recommended_format';
  static const _autoApplyKey = 'ab.auto_apply';
  static const _overridePrefix = 'ab.overrides.';

  static const FormatMeta _defaultFormat =
      FormatMeta(spotsPerPack: 12, streets: 1, theoryRatio: 0.5);

  bool _autoApply = true;
  FormatMeta? _recommended;
  final Map<String, FormatMeta> _overrides = {};

  bool get autoApply => _autoApply;

  /// Loads stored preferences for recommended format and overrides.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoApply = prefs.getBool(_autoApplyKey) ?? true;

    final raw = prefs.getString(_recommendedKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _recommended = FormatMeta.fromJson(data);
      } catch (_) {
        _recommended = null;
      }
    }

    _overrides.clear();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_overridePrefix)) {
        final aud = key.substring(_overridePrefix.length);
        final r = prefs.getString(key);
        if (r != null) {
          try {
            final data = jsonDecode(r) as Map<String, dynamic>;
            _overrides[aud] = FormatMeta.fromJson(data);
          } catch (_) {}
        }
      }
    }
  }

  /// Returns the effective format, considering audience-specific overrides.
  FormatMeta effectiveFormat({String? audience}) {
    if (audience != null && _overrides.containsKey(audience)) {
      return _overrides[audience]!;
    }
    return _recommended ?? _defaultFormat;
  }

  /// Applies the effective format to [gen]'s parameters.
  void applyTo(TrainingPackAutoGenerator gen, {String? audience}) {
    final fmt = effectiveFormat(audience: audience);
    gen.spotsPerPack = fmt.spotsPerPack;
    gen.streets = fmt.streets;
    gen.theoryRatio = fmt.theoryRatio;
    if (_recommended == null) {
      AutogenPipelineEventLoggerService.log(
          'notice', 'AutoFormat: fallback (no winner)');
    }
  }
}
