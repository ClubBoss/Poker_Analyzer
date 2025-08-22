import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('audit exists', () {
    expect(File('tooling/content_audit.dart').existsSync(), isTrue);
  });
}
