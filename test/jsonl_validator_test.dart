import 'package:poker_analyzer/content/jsonl_validator.dart';
import 'package:test/test.dart';

void main() {
  group('validateJsonl', () {
    test('happy path with comments and blanks', () {
      const src = r'''
# demo file

{"id":"a1","x":1}
  
# comment
{"id":"b2","y":"z"}
''';
      final rep = validateJsonl(src);
      expect(rep.ok, isTrue);
      expect(rep.count, 2);
      expect(rep.issues, isEmpty);
      expect(rep.ids.length, 2);
      expect(rep.ids.contains('a1'), isTrue);
      expect(rep.ids.contains('b2'), isTrue);
    });

    test('id format: colon is invalid', () {
      const src = '{"id":"a:b"}\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isFalse);
      expect(
        rep.issues.any(
          (e) => e.message == 'invalid id: must match ^[a-z0-9_]+\$',
        ),
        isTrue,
      );
    });

    test('id format: hyphen is invalid', () {
      const src = '{"id":"abc-def"}\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isFalse);
      expect(
        rep.issues.any(
          (e) => e.message == 'invalid id: must match ^[a-z0-9_]+\$',
        ),
        isTrue,
      );
    });

    test('id format: uppercase is invalid', () {
      const src = '{"id":"Abc"}\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isFalse);
      expect(
        rep.issues.any(
          (e) => e.message == 'invalid id: must match ^[a-z0-9_]+\$',
        ),
        isTrue,
      );
    });

    test('id format: valid canonical id passes', () {
      const src = '{"id":"math_intro_basics_drill_001"}\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isTrue);
      expect(rep.issues, isEmpty);
    });

    test('duplicate id', () {
      const src = '{"id":"dup"}\n{"id":"dup"}\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isFalse);
      expect(rep.count, 2);
      expect(rep.issues.any((e) => e.message.contains('duplicate id')), isTrue);
    });

    test('non-JSON line', () {
      const src = '{"id":"ok"}\nnot-json-here\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isFalse);
      expect(rep.count, 2);
      expect(rep.issues.any((e) => e.message.contains('invalid JSON')), isTrue);
    });

    test('non-ASCII line is flagged', () {
      const src = '{"id":"ok"}\n{"id":"тест"}\n';
      final rep = validateJsonl(src);
      expect(rep.ok, isFalse);
      // second line should have two issues: line non-ascii and id non-ascii
      expect(
        rep.issues.any((e) => e.message.contains('non-ASCII content')),
        isTrue,
      );
      expect(rep.issues.any((e) => e.message.contains('ASCII-only')), isTrue);
    });

    test('custom idField and asciiOnly=false', () {
      const src = '{"_id":"äëïöú"}\n';
      final rep = validateJsonl(src, idField: '_id', asciiOnly: false);
      expect(rep.ok, isFalse, reason: 'id must still be ASCII');
      expect(rep.count, 1);
      expect(
        rep.issues.any(
          (e) => e.message.contains("field '_id' must be ASCII-only"),
        ),
        isTrue,
      );
    });
  });
}
