import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/mastery_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('exportToJson filters, rounds and sorts entries', () {
    final service = MasteryExportService();
    final jsonStr = service.exportToJson({
      'b': 0.5555,
      'a': 1.2,
      'c': -0.1,
      'a2': 0.12349,
    });
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    expect(data['schemaVersion'], '1.0');
    expect(DateTime.tryParse(data['exportedAt'] as String), isNotNull);
    final tags = data['tags'] as Map<String, dynamic>;
    expect(tags.keys.toList(), ['a2', 'b']);
    expect(tags['a2'], 0.123);
    expect(tags['b'], 0.556);
  });
}
