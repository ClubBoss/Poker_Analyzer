import 'dart:convert';
import 'dart:io';

void main() {
  const stacks = [10, 20, 40, 100];
  const positions = ['SB', 'BB', 'UTG', 'MP', 'CO', 'BTN'];
  const hands = [
    'AsKs',
    'AhAd',
    'QcQd',
    'JcJh',
    'TsTd',
    '9c9d',
    '8s8h',
    '7d7c',
    '6s6d',
    '5h5s',
    '4c4d',
    '3s3h',
  ];

  final spots = <Map<String, String>>[];
  var id = 1;
  var toggle = true;

  for (final stack in stacks) {
    for (final pos in positions) {
      final spot = <String, String>{
        'id': 's$id',
        'kind': 'l3_postflop_jam',
        'hand': hands[(id - 1) % hands.length],
        'pos': pos,
        'stack': '${stack}bb',
        'action': toggle ? 'jam' : 'fold',
      };
      if (id % 5 == 0) spot['vsPos'] = 'BB';
      if (id % 7 == 0) spot['limpers'] = 'UTG';
      if (id % 11 == 0) spot['explain'] = 'demo';
      spots.add(spot);
      id++;
      toggle = !toggle;
    }
  }

  toggle = true;
  for (final stack in stacks) {
    for (final pos in positions) {
      final spot = <String, String>{
        'id': 's$id',
        'kind': 'callVsJam',
        'hand': hands[(id - 1) % hands.length],
        'pos': pos,
        'stack': '${stack}bb',
        'action': toggle ? 'call' : 'fold',
      };
      if (id % 5 == 0) spot['vsPos'] = 'BB';
      if (id % 7 == 0) spot['limpers'] = 'UTG';
      if (id % 11 == 0) spot['explain'] = 'demo';
      spots.add(spot);
      id++;
      toggle = !toggle;
    }
  }

  final file = File('out/seed_spots.json');
  file.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(spots));
  print('Seed: ${spots.length} spots -> out/seed_spots.json');
}
