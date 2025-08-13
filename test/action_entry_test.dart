import 'package:test/test.dart';
import 'package:poker_analyzer/models/action_entry.dart';

void main() {
  test('ActionEntry.copy creates independent instance', () {
    final a = ActionEntry(0, 1, 'push', ev: 1.0);
    final b = a.copy();
    expect(identical(a, b), isFalse);
    expect(b.ev, 1.0);
  });

  test('ActionEntry.copyWith overrides selected fields', () {
    final a = ActionEntry(0, 1, 'push', ev: 1.0);
    final b = a.copyWith(action: 'call', ev: 2.0);
    expect(b.action, 'call');
    expect(b.ev, 2.0);
    expect(a.action, 'push');
    expect(a.ev, 1.0);
  });
}
