import 'package:test/test.dart';

import 'package:poker_analyzer/content/jsonl_loader.dart';

void main() {
  group('parseJsonl', () {
    test('happy path parses two objects and preserves IDs', () {
      final src = [
        '# header comment',
        '',
        '{"id":"a1","title":"One"}',
        '{"id":"b2","title":"Two"}',
      ].join('\n');

      final out = parseJsonl(src);
      expect(out.length, 2);
      expect(out[0]['id'], 'a1');
      expect(out[1]['id'], 'b2');
    });

    test('duplicate id triggers validation failure', () {
      final src = [
        '{"id":"dup","title":"X"}',
        '{"id":"dup","title":"Y"}',
      ].join('\n');

      expect(
        () => parseJsonl(src),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('validation failed'),
          ),
        ),
      );
    });

    test('non-object line triggers validation failure', () {
      final src = ['# comment', '["x"]'].join('\n');

      expect(
        () => parseJsonl(src),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            allOf(contains('validation failed'), contains('not a JSON object')),
          ),
        ),
      );
    });

    test('invalid JSON line throws FormatException', () {
      final src = '{"id":"ok"'; // missing closing brace
      expect(() => parseJsonl(src), throwsA(isA<FormatException>()));
    });

    test('asciiOnly=false allows non-ASCII text in fields', () {
      final src = '{"id":"ok1","title":"Caf\u00e9"}';
      final out = parseJsonl(src, asciiOnly: false);
      expect(out.length, 1);
      expect(out.first['id'], 'ok1');
      expect(out.first['title'], 'Café');
    });
  });
}
