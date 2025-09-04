// ASCII-only; pure Dart (no Flutter deps)

import 'live_context.dart';
import 'live_mode.dart';

export 'live_context.dart' show LiveContext;
export 'live_mode.dart' show TrainingMode;

const Map<String, LiveContext> kLiveDefaults = <String, LiveContext>{
  'live_tells_and_dynamics': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: true,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_etiquette_and_procedures': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: true,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_full_ring_adjustments': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 2,
    announceRequired: false,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: 'slow',
  ),
  'live_special_formats_straddle_bomb_ante': LiveContext(
    hasStraddle: true,
    bombAnte: true,
    multiLimpers: 0,
    announceRequired: false,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_table_selection_and_seat_change': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: false,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_chip_handling_and_bet_declares': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: true,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_speech_timing_basics': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: true,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: 'slow',
  ),
  'live_rake_structures_and_tips': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: false,
    rakeType: 'drop',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_floor_calls_and_dispute_resolution': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: true,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_session_log_and_review': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: false,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
  'live_security_and_game_integrity': LiveContext(
    hasStraddle: false,
    bombAnte: false,
    multiLimpers: 0,
    announceRequired: false,
    rakeType: '',
    avgStackBb: 0,
    tableSpeed: '',
  ),
};

LiveContext defaultLiveContextFor({
  required TrainingMode mode,
  required String moduleId,
}) {
  if (mode != TrainingMode.live) return const LiveContext.off();
  if (moduleId.startsWith('live_'))
    return kLiveDefaults[moduleId] ?? const LiveContext.off();
  if (moduleId.startsWith('cash_') || moduleId.startsWith('mtt_'))
    return const LiveContext.off();
  return const LiveContext.off();
}
