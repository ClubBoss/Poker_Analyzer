import 'package:flutter_test/flutter_test.dart';
import 'package:poker_ai_analyzer/utils/eth_utils.dart';

void main() {
  group('isValidAddress', () {
    test('valid addresses', () {
      expect(isValidAddress('0xae2a9c9ea2434a9b9b27d7522514129c218d09e8'), isTrue);
      expect(isValidAddress('0xAE2A9C9EA2434A9B9B27D7522514129C218D09E8'), isTrue);
    });

    test('invalid addresses', () {
      expect(isValidAddress('0x123'), isFalse);
      expect(isValidAddress('ae2a9c9ea2434a9b9b27d7522514129c218d09e8'), isFalse);
    });
  });

  group('toChecksumAddress', () {
    test('converts to checksum', () {
      const addr = '0xae2a9c9ea2434a9b9b27d7522514129c218d09e8';
      expect(toChecksumAddress(addr), '0xae2A9c9Ea2434a9b9B27D7522514129c218D09e8');
    });
  });
}
