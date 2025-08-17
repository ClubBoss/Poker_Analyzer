import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('canonical guard occurs exactly once', () {
    final source = File(
      'lib/ui/session_player/mvs_player.dart',
    ).readAsStringSync();
    final pattern = RegExp(r'\bisAutoReplayKind\(\s*spot\.kind\s*\)');
    final count = pattern.allMatches(source).length;
    expect(
      count,
      1,
      reason:
          'Canonical guard must exist exactly once (centralized). Found $count occurrences.',
    );
  });
}
