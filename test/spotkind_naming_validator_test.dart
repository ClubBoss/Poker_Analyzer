import 'package:test/test.dart';

void main() {
  // SpotKind naming: l{level}_{scope}_{pattern...}
  final regex = RegExp(r'^l\d+_[a-z]+_[a-z_]+$');

  test('naming regex compiles', () {
    expect(regex.hasMatch('l3_flop_jam_vs_raise'), isTrue);
    expect(regex.hasMatch('l4_icm_bb_jam_vs_fold'), isTrue);
    expect(regex.hasMatch('badName'), isFalse);
  });
}
