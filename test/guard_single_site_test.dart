import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('canonical guard occurs exactly once', () {
    // Read canonical guard site only.
    final src = File(
      'lib/ui/session_player/spot_specs.dart',
    ).readAsStringSync();

    // Strip line comments to avoid counting the documentation hint.
    final code = src
        .split('\n')
        .map((l) => l.contains('//') ? l.substring(0, l.indexOf('//')) : l)
        .join('\n');

    // 1) Exactly one occurrence of _autoReplayKinds.contains(
    final occContains = RegExp(
      r'_autoReplayKinds\.contains\(',
    ).allMatches(code).length;
    expect(
      occContains,
      1,
      reason:
          'Expected exactly one _autoReplayKinds.contains( occurrence; found $occContains.',
    );

    // 2) Guard shape exists exactly once as a single normalized string.
    final normalized = code.replaceAll(RegExp(r'\s+'), ' ').trim();
    const guard =
        '!correct && autoWhy && _autoReplayKinds.contains(spot.kind) && !_replayed.contains(spot)';
    final occGuard = RegExp(RegExp.escape(guard)).allMatches(normalized).length;
    expect(
      occGuard,
      1,
      reason: 'Canonical guard must exist exactly once; found $occGuard.',
    );
  });
}
