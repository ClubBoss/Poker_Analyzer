import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';

void main() {
  test('curriculum status', () {
    final file = File('curriculum_status.json');
    expect(file.existsSync(), isTrue);

    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final modulesDone = (data['modules_done'] as List).cast<String>();
    expect(modulesDone, isA<List<String>>());

    expect(modulesDone.last, equals('cash:l3:v1'));

    print('NEXT modules_done: ${modulesDone.join(',')}');
  });
}
