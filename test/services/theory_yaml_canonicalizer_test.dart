import 'package:test/test.dart';
import 'package:poker_analyzer/services/theory_yaml_canonicalizer.dart';

void main() {
  test('canonicalization stable & fast', () {
    final data = <String, dynamic>{};
    for (var i = 0; i < 1000; i++) {
      data['k${1000 - i}'] = i;
    }
    const canonizer = TheoryYamlCanonicalizer();
    final sw = Stopwatch()..start();
    final c1 = canonizer.canonicalize(data);
    sw.stop();
    final elapsed = sw.elapsedMilliseconds;
    final c2 = canonizer.canonicalize(data);
    expect(c1, c2);
    expect(elapsed, lessThan(200));
  });
}
