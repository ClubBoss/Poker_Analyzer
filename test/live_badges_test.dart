// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_mode.dart';
import 'package:poker_analyzer/live/live_badges.dart';
import 'package:poker_analyzer/live/live_ui_maps.dart';

void main() {
  group('liveBadgesForModule', () {
    test('live_tells_and_dynamics -> [] in online, ["Live"] in live', () {
      const id = 'live_tells_and_dynamics';
      final inOnline = liveBadgesForModule(
        moduleId: id,
        mode: TrainingMode.online,
      );
      final inLive = liveBadgesForModule(moduleId: id, mode: TrainingMode.live);

      expect(inOnline, isEmpty);
      expect(inLive, equals(<String>[kLiveBadgeText]));
    });

    test('cash_rake_and_stakes -> [] in online, ["Live"] in live', () {
      const id = 'cash_rake_and_stakes';
      final inOnline = liveBadgesForModule(
        moduleId: id,
        mode: TrainingMode.online,
      );
      final inLive = liveBadgesForModule(moduleId: id, mode: TrainingMode.live);

      expect(inOnline, isEmpty);
      expect(inLive, equals(<String>[kLiveBadgeText]));
    });

    test('mtt_short_stack -> [] in online, ["Live"] in live', () {
      const id = 'mtt_short_stack';
      final inOnline = liveBadgesForModule(
        moduleId: id,
        mode: TrainingMode.online,
      );
      final inLive = liveBadgesForModule(moduleId: id, mode: TrainingMode.live);

      expect(inOnline, isEmpty);
      expect(inLive, equals(<String>[kLiveBadgeText]));
    });

    test('non-matching id -> [] in both modes', () {
      const id = 'math_ev_calculations';
      final inOnline = liveBadgesForModule(
        moduleId: id,
        mode: TrainingMode.online,
      );
      final inLive = liveBadgesForModule(moduleId: id, mode: TrainingMode.live);

      expect(inOnline, isEmpty);
      expect(inLive, isEmpty);
    });

    test('no duplicates for overlapping conditions', () {
      // Starts with "live_" and also matches mode==live
      const id = 'live_mtt_short_stack';
      final badges = liveBadgesForModule(moduleId: id, mode: TrainingMode.live);

      expect(badges, equals(<String>[kLiveBadgeText]));
      expect(badges.where((b) => b == kLiveBadgeText).length, 1);
    });
  });
}
