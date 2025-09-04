// ASCII-only; pure Dart test (no Flutter imports)

import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_runtime.dart';
import 'package:poker_analyzer/live/live_defaults.dart';
import 'package:poker_analyzer/live/live_context_format.dart';

void main() {
  final ids = [
    'live_tells_and_dynamics',
    'live_etiquette_and_procedures',
    'live_full_ring_adjustments',
    'live_special_formats_straddle_bomb_ante',
    'live_table_selection_and_seat_change',
    'live_chip_handling_and_bet_declares',
    'live_speech_timing_basics',
    'live_rake_structures_and_tips',
    'live_floor_calls_and_dispute_resolution',
    'live_session_log_and_review',
    'live_security_and_game_integrity',
  ];

  group('Live facade smoke', () {
    test('online mode: live modules off, no badges/subtitles', () {
      LiveRuntime.setMode(TrainingMode.online);
      for (final id in ids) {
        expect(LiveRuntime.badgesForModule(id), isEmpty);
        expect(LiveRuntime.subtitleFor(id), isEmpty);
        expect(LiveRuntime.contextFor(id).isOff, isTrue);
      }
    });

    test('live mode: live modules show Live badge and default context', () {
      LiveRuntime.setMode(TrainingMode.live);
      for (final id in ids) {
        expect(LiveRuntime.badgesForModule(id), equals(['Live']));
        final ctx = LiveRuntime.contextFor(id);
        expect(ctx, equals(kLiveDefaults[id]));
        final subtitle = LiveRuntime.subtitleFor(id);
        expect(subtitle, equals(liveContextSubtitle(kLiveDefaults[id]!)));
      }
    });

    test(
      'live mode: non-live modules get Live badge but no context/subtitle',
      () {
        LiveRuntime.setMode(TrainingMode.live);
        for (final id in ['cash_rake_and_stakes', 'mtt_short_stack']) {
          expect(LiveRuntime.badgesForModule(id), equals(['Live']));
          expect(LiveRuntime.contextFor(id).isOff, isTrue);
          expect(LiveRuntime.subtitleFor(id), isEmpty);
        }
      },
    );
  });
}
