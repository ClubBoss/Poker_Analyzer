import 'texture_keys.dart';

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
      kMonotoneKey: 0.05,
      kTwoToneKey: 0.30,
      kRainbowKey: 0.65,
      kPairedKey: 0.17,
      kAceHighKey: 0.22,
      kLowConnectedKey: 0.18,
      kBroadwayHeavyKey: 0.38,
    },
  ),
};
