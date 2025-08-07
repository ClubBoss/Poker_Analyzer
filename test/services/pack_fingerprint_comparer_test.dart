import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/pack_fingerprint_comparer.dart';

void main() {
  test('detects duplicate and high similarity packs', () {
    final comparer = const PackFingerprintComparer();
    final newPack = PackFingerprint(
      id: 'new',
      hash: 'hash1',
      spots: {for (var i = 0; i < 10; i++) 's$i'},
    );
    final duplicate = PackFingerprint(
      id: 'existing1',
      hash: 'hash1',
      spots: {for (var i = 0; i < 10; i++) 's$i'},
    );
    final similar = PackFingerprint(
      id: 'existing2',
      hash: 'hash2',
      spots: {...{for (var i = 0; i < 9; i++) 's$i'}, 'x'},
    );
    final different = PackFingerprint(
      id: 'existing3',
      hash: 'hash3',
      spots: {'a', 'b'},
    );

    final reports =
        comparer.compare(newPack, [duplicate, similar, different]);
    expect(reports.length, 2);
    expect(reports[0].existingPackId, 'existing1');
    expect(reports[0].reason, 'duplicate');
    expect(reports[0].similarity, 1.0);
    expect(reports[1].existingPackId, 'existing2');
    expect(reports[1].reason, 'high similarity');
    expect(reports[1].similarity, closeTo(0.9, 1e-9));
  });
});
