import 'dart:io';
import 'package:test/test.dart';

void main() {
  final src = File('lib/ui/session_player/mvs_player.dart').readAsStringSync();

  group('SpotKind integrity', () {
    test('jam_vs actions map', () {
      final m = RegExp(
        r'const _actionsMap = <SpotKind, List<String>>{([^}]+)};',
      ).firstMatch(src)!;
      final entries = RegExp(
        r"SpotKind\\.(\\w+): \['([^']+)', '([^']+)'\]",
      ).allMatches(m.group(1)!);
      for (final e in entries) {
        final name = e.group(1)!;
        final a = e.group(2)!;
        final b = e.group(3)!;
        if (name.contains('jam_vs_')) {
          expect([a, b], ['jam', 'fold']);
        }
      }
    });

    test('subtitle prefixes', () {
      final m = RegExp(
        r'const _subtitlePrefix = <SpotKind, String>{([^}]+)};',
      ).firstMatch(src)!;
      final entries = RegExp(
        r"SpotKind\\.(\\w+): '([^']+)'\,",
      ).allMatches(m.group(1)!);
      for (final e in entries) {
        final name = e.group(1)!;
        final prefix = e.group(2)!;
        expect(prefix.isNotEmpty, true);
        if (name.contains('flop')) {
          expect(prefix.startsWith('Flop Jam'), true);
        } else if (name.contains('turn')) {
          expect(prefix.startsWith('Turn Jam'), true);
        } else if (name.contains('river')) {
          expect(prefix.startsWith('River Jam'), true);
        } else if (name.contains('icm')) {
          expect(prefix.startsWith('ICM'), true);
        }
      }
    });

    test('autoReplayKinds covered', () {
      final auto = RegExp(
        r'const _autoReplayKinds = {([^}]+)};',
      ).firstMatch(src)!;
      final autoKinds = RegExp(
        r'SpotKind\\.(\\w+)',
      ).allMatches(auto.group(1)!).map((e) => e.group(1)!).toSet();

      final act = RegExp(
        r'const _actionsMap = <SpotKind, List<String>>{([^}]+)};',
      ).firstMatch(src)!;
      final actionKinds = RegExp(
        r'SpotKind\\.(\\w+)',
      ).allMatches(act.group(1)!).map((e) => e.group(1)!).toSet();

      final sub = RegExp(
        r'const _subtitlePrefix = <SpotKind, String>{([^}]+)};',
      ).firstMatch(src)!;
      final subtitleKinds = RegExp(
        r'SpotKind\\.(\\w+)',
      ).allMatches(sub.group(1)!).map((e) => e.group(1)!).toSet();

      expect(actionKinds.containsAll(autoKinds), true);
      expect(subtitleKinds.containsAll(autoKinds), true);
    });
  });
}
