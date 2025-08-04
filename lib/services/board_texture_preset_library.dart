import '../models/constraint_set.dart';

/// Provides predefined board texture presets that expand to board constraint
/// parameter maps suitable for [ConstraintSet.boardConstraints].
class BoardTexturePresetLibrary {
  static final Map<String, Map<String, dynamic>> _presets = {
    'lowpaired': {
      'requiredTextures': ['paired', 'low', 'rainbow'],
    },
    'dryacehigh': {
      'requiredTextures': ['aceHigh', 'rainbow'],
      'excludedTags': ['straightDrawHeavy'],
    },
    'connectedmono': {
      'requiredTextures': ['connected', 'monotone'],
    },
    'broadwayrainbow': {
      'requiredTextures': ['broadway', 'rainbow'],
    },
  };

  /// Returns a constraint map for the given [presetName].
  ///
  /// Throws [ArgumentError] if [presetName] is not a supported preset.
  static Map<String, dynamic> get(String presetName) {
    final key = presetName.toLowerCase();
    final preset = _presets[key];
    if (preset == null) {
      throw ArgumentError('Unknown board texture preset: $presetName');
    }
    // Return a copy to prevent external mutation.
    return Map<String, dynamic>.from(preset);
  }
}
