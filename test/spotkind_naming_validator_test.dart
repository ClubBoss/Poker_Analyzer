import 'package:test/test.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('SpotKind names follow l<num>_word_word format', () {
    final regex = RegExp('^l\\d+_[a-z]+_[a-z_]+$');
    final bad = [
      for (final k in SpotKind.values)
        if (!regex.hasMatch(k.name) ||
            k.name.contains(RegExp(r'[^a-z0-9_]')))
          k.name
    ];
    expect(bad, isEmpty, reason: 'Invalid SpotKind names: ${bad.join(', ')}');
  });
}
