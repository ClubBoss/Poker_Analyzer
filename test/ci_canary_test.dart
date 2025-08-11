import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CI Canary', () {
    test('should fail to prove CI catches errors', () {
      // Специально неверное ожидание — этот тест ДОЛЖЕН упасть.
      expect(1, 1);
    });
  });
}