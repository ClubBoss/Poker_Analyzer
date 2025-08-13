import 'package:test/test.dart';

const _ranks = [
  'A',
  'K',
  'Q',
  'J',
  'T',
  '9',
  '8',
  '7',
  '6',
  '5',
  '4',
  '3',
  '2',
];
const _suits = ['s', 'h', 'd', 'c'];

List<String> _buildDeck() {
  return [
    for (final r in _ranks)
      for (final s in _suits) '$r$s',
  ];
}

bool _isPaired(List<String> flop) {
  final ranks = flop.map((c) => c[0]).toList();
  return ranks[0] == ranks[1] || ranks[0] == ranks[2] || ranks[1] == ranks[2];
}

String _texture(List<String> flop) {
  final suits = flop.map((c) => c[1]).toSet();
  if (suits.length == 1) return 'monotone';
  if (suits.length == 2) return 'twoTone';
  return 'rainbow';
}

void main() {
  test('paired & monotone flops are impossible', () {
    final deck = _buildDeck();
    var count = 0;
    for (var i = 0; i < deck.length; i++) {
      for (var j = i + 1; j < deck.length; j++) {
        for (var k = j + 1; k < deck.length; k++) {
          final flop = [deck[i], deck[j], deck[k]];
          if (_isPaired(flop) && _texture(flop) == 'monotone') {
            count++;
          }
        }
      }
    }
    expect(count, 0);
  });
}
