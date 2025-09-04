import 'package:test/test.dart';
import 'package:poker_analyzer/curriculum/unit_id_utils.dart';

bool _isAscii(String s) => s.codeUnits.every((c) => c <= 0x7F);

void main() {
  test('canonical pack labels match exact ASCII literals', () {
    expect(kPackL1, 'L1');
    expect(kPackL2, 'L2');
    expect(kPackBridge, 'BRIDGE');
    expect(kPackCheckpoint, 'CHECKPOINT');
    expect(kPackBoss, 'BOSS');
  });

  test('canonical pack labels are ASCII only', () {
    for (final s in [
      kPackL1,
      kPackL2,
      kPackBridge,
      kPackCheckpoint,
      kPackBoss,
    ]) {
      expect(
        _isAscii(s),
        isTrue,
        reason: 'Non-ASCII byte found in: \'' + s + '\'',
      );
    }
  });
}
