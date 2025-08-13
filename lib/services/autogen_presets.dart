/// Autogen presets for board generation.
///
/// Currently only `postflop_default` is provided with a target mix.
class AutogenPreset {
  final Map<String, double> targetMix;
  const AutogenPreset({required this.targetMix});
}

/// Registry of available presets.
const Map<String, AutogenPreset> kAutogenPresets = {
  'postflop_default': AutogenPreset(
    targetMix: {
      'monotone': 0.05,
      'twoTone': 0.30,
      'rainbow': 0.65,
      'paired': 0.17,
      'aceHigh': 0.22,
      'lowConnected': 0.18,
      'broadwayHeavy': 0.38,
    },
  ),
};
