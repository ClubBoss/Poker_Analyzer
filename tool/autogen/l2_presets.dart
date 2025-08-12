class L2Preset {
  final String name;
  final String subtype;
  final List<String> positions;
  final List<String> stackBuckets;
  final bool limped;

  const L2Preset({
    required this.name,
    required this.subtype,
    this.positions = const [],
    this.stackBuckets = const [],
    this.limped = false,
  });
}

const Map<String, L2Preset> l2Presets = {
  'open-fold': L2Preset(
    name: 'open-fold',
    subtype: 'open-fold',
    positions: ['EP', 'MP', 'CO', 'BTN', 'SB', 'BB'],
  ),
  '3bet-push': L2Preset(
    name: '3bet-push',
    subtype: '3bet-push',
    stackBuckets: ['8-12', '13-18', '19-25', '26-32', '33-40', '41-50'],
  ),
  'limped': L2Preset(
    name: 'limped',
    subtype: 'limped',
    positions: ['SB', 'BB'],
    limped: true,
  ),
};

const List<String> allPresets = ['open-fold', '3bet-push', 'limped'];
