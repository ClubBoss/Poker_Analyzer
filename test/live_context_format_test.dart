import 'package:test/test.dart';
import 'package:poker_analyzer/live/live_context.dart';
import 'package:poker_analyzer/live/live_context_format.dart';

void main() {
  test('LiveContext.off() -> empty tags and subtitle', () {
    const ctx = LiveContext.off();
    expect(liveContextTags(ctx), <String>[]);
    expect(liveContextSubtitle(ctx), '');
  });

  test('Example tags and subtitle', () {
    const ctx = LiveContext(
      hasStraddle: true,
      bombAnte: false,
      multiLimpers: 3,
      announceRequired: true,
      rakeType: 'drop',
      avgStackBb: 0,
      tableSpeed: 'slow',
    );
    expect(liveContextTags(ctx), <String>[
      'announce',
      'straddle',
      'limpers:3',
      'rake:drop',
      'speed:slow',
    ]);
    expect(
      liveContextSubtitle(ctx),
      'announce, straddle, limpers:3, rake:drop, speed:slow',
    );
  });

  test('Determinism: tag order stable', () {
    const a = LiveContext(
      hasStraddle: true,
      bombAnte: true,
      multiLimpers: 2,
      announceRequired: true,
      rakeType: 'time',
      avgStackBb: 0,
      tableSpeed: 'fast',
    );

    // Same values, different constructor argument order
    const b = LiveContext(
      announceRequired: true,
      multiLimpers: 2,
      bombAnte: true,
      tableSpeed: 'fast',
      hasStraddle: true,
      avgStackBb: 0,
      rakeType: 'time',
    );

    final expected = <String>[
      'announce',
      'straddle',
      'bomb_ante',
      'limpers:2',
      'rake:time',
      'speed:fast',
    ];
    expect(liveContextTags(a), expected);
    expect(liveContextTags(b), expected);
  });

  test('Boundary: avgStackBb adds last tag', () {
    const ctx = LiveContext(
      hasStraddle: true,
      bombAnte: false,
      multiLimpers: 1,
      announceRequired: true,
      rakeType: 'drop',
      avgStackBb: 180,
      tableSpeed: 'normal',
    );
    expect(liveContextTags(ctx), <String>[
      'announce',
      'straddle',
      'limpers:1',
      'rake:drop',
      'speed:normal',
      'avg_bb:180',
    ]);
  });

  test('Invalid/empty values are omitted', () {
    const ctx = LiveContext(
      hasStraddle: false,
      bombAnte: false,
      multiLimpers: 0,
      announceRequired: false,
      rakeType: '',
      avgStackBb: 0,
      tableSpeed: '',
    );
    expect(liveContextTags(ctx), <String>[]);
  });
}
