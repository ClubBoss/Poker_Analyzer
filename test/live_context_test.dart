import 'package:test/test.dart';

import 'package:poker_analyzer/live/live_context.dart';

void main() {
  group('LiveContext', () {
    test('off() has defaults and isOff == true', () {
      const off = LiveContext.off();
      expect(off.isOff, isTrue);
      expect(off.hasStraddle, isFalse);
      expect(off.bombAnte, isFalse);
      expect(off.multiLimpers, 0);
      expect(off.announceRequired, isFalse);
      expect(off.rakeType, '');
      expect(off.avgStackBb, 0);
      expect(off.tableSpeed, '');
    });

    test('copyWith updates only specified fields', () {
      const off = LiveContext.off();
      final updated = off.copyWith(hasStraddle: true, multiLimpers: 3);

      expect(updated.hasStraddle, isTrue);
      expect(updated.multiLimpers, 3);
      // Unchanged fields remain defaults
      expect(updated.bombAnte, isFalse);
      expect(updated.announceRequired, isFalse);
      expect(updated.rakeType, '');
      expect(updated.avgStackBb, 0);
      expect(updated.tableSpeed, '');
      expect(updated.isOff, isFalse);

      // copyWith with no args returns equal object values
      final same = off.copyWith();
      expect(same, off);
    });

    test('allowed domain examples construct correctly', () {
      expect(
        () => LiveContext(
          hasStraddle: false,
          bombAnte: false,
          multiLimpers: 2,
          announceRequired: true,
          rakeType: 'time',
          avgStackBb: 75,
          tableSpeed: 'slow',
        ),
        returnsNormally,
      );

      expect(
        () => LiveContext(
          hasStraddle: true,
          bombAnte: true,
          multiLimpers: 1,
          announceRequired: false,
          rakeType: 'drop',
          avgStackBb: 120,
          tableSpeed: 'fast',
        ),
        returnsNormally,
      );

      // Normal speed and blank rake/speed
      final ctx = LiveContext(
        hasStraddle: false,
        bombAnte: true,
        multiLimpers: 0,
        announceRequired: false,
        rakeType: '',
        avgStackBb: 0,
        tableSpeed: 'normal',
      );
      expect(ctx.rakeType, '');
      expect(ctx.tableSpeed, 'normal');
    });

    test('equality and hashCode reflect field equality', () {
      final a = LiveContext(
        hasStraddle: true,
        bombAnte: false,
        multiLimpers: 4,
        announceRequired: false,
        rakeType: 'time',
        avgStackBb: 50,
        tableSpeed: 'normal',
      );
      final b = LiveContext(
        hasStraddle: true,
        bombAnte: false,
        multiLimpers: 4,
        announceRequired: false,
        rakeType: 'time',
        avgStackBb: 50,
        tableSpeed: 'normal',
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
