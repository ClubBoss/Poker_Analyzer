import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/tag_mastery_importer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('importFromJson normalizes and clamps values', () {
    const jsonStr =
        '{"schemaVersion":"1.0","exportedAt":"2024-01-01T00:00:00Z","tags":{"A":0.8,"B":"1.2"," ":0.5,"c":-0.1}}';
    final importer = TagMasteryImporter();
    final map = importer.importFromJson(jsonStr);
    expect(map, {'a': 0.8, 'b': 1.0, 'c': 0.0});
  });

  test('importFromJson returns empty map on malformed input', () {
    const badJson = '{"tags": [1,2,3]}';
    final importer = TagMasteryImporter();
    final map = importer.importFromJson(badJson);
    expect(map, isEmpty);
  });
}
