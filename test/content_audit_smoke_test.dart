import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('content audit binary exists', () {
    expect(File('tooling/content_audit.dart').existsSync(), isTrue);
  });
}
