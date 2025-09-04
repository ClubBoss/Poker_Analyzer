// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_ids.dart';
import 'package:poker_analyzer/live/live_progress.dart';

void main() {
  group('computeLiveProgress', () {
    test('empty input', () {
      final progress = computeLiveProgress(<String>{});
      expect(progress.done, equals(0));
      expect(progress.total, equals(kLiveModuleIds.length));
      expect(progress.remaining, equals(kLiveModuleIds));
      expect(progress.pct, equals(0.0));
    });

    test('half-done (first 5 ids)', () {
      final firstFive = kLiveModuleIds.take(5).toSet();
      final progress = computeLiveProgress(firstFive);
      expect(progress.done, equals(5));
      expect(progress.total, equals(kLiveModuleIds.length));
      expect(progress.remaining, equals(kLiveModuleIds.skip(5).toList()));
      expect(progress.pct, equals(5 / 11));
    });

    test('all-done', () {
      final all = kLiveModuleIds.toSet();
      final progress = computeLiveProgress(all);
      expect(progress.done, equals(kLiveModuleIds.length));
      expect(progress.total, equals(kLiveModuleIds.length));
      expect(progress.remaining.isEmpty, isTrue);
      expect(progress.pct, equals(1.0));
    });

    test('ignores extra non-live IDs', () {
      final input = kLiveModuleIds.take(3).toSet()
        ..addAll({'not_real_id', 'another_fake'});
      final progress = computeLiveProgress(input);
      expect(progress.done, equals(3));
      expect(progress.total, equals(kLiveModuleIds.length));
      expect(progress.remaining, equals(kLiveModuleIds.skip(3).toList()));
      expect(progress.pct, equals(3 / 11));
    });
  });
}
