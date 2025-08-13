class L3Preset {
  final String name;
  final Map<String, double> targetMix;
  final bool Function(List<String> flop)? filter;

  const L3Preset({required this.name, required this.targetMix, this.filter});
}

bool _paired(List<String> flop) {
  final ranks = flop.map((c) => c[0]).toList();
  return ranks[0] == ranks[1] || ranks[0] == ranks[2] || ranks[1] == ranks[2];
}

bool _unpaired(List<String> flop) => !_paired(flop);

bool _aceHigh(List<String> flop) => flop.any((c) => c[0] == 'A');

const Map<String, L3Preset> l3Presets = {
  'paired': L3Preset(
    name: 'paired',
    // paired∧monotone impossible because a pair requires two suits
    targetMix: {'monotone': 0.0, 'twoTone': 0.50, 'rainbow': 0.50},
    filter: _paired,
  ),
  'unpaired': L3Preset(
    name: 'unpaired',
    targetMix: {'monotone': 0.2, 'twoTone': 0.3, 'rainbow': 0.5},
    filter: _unpaired,
  ),
  'ace-high': L3Preset(
    name: 'ace-high',
    targetMix: {'monotone': 0.2, 'twoTone': 0.3, 'rainbow': 0.5},
    filter: _aceHigh,
  ),
  'broadway': L3Preset(
    name: 'broadway',
    targetMix: {'monotone': 0.2, 'twoTone': 0.3, 'rainbow': 0.5},
    filter: _broadway,
  ),
};

List<String> get allPresets => l3Presets.keys.toList();

bool _broadway(List<String> flop) {
  const broadway = {'A', 'K', 'Q', 'J', 'T'};
  return flop.where((c) => broadway.contains(c[0])).length >= 2;
}
