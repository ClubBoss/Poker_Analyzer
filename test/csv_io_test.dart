import 'dart:io';

import 'package:poker_analyzer/utils/csv_io.dart';
import 'package:test/test.dart';

void main() {
  group('writeCsv', () {
    test('writes BOM and CRLF on Windows', () async {
      final dir = await Directory.systemTemp.createTemp('csv_io_test_');
      final file = File('${dir.path}/out.csv');
      final buffer = StringBuffer()
        ..writeln('a,b')
        ..write('c,d');

      await writeCsv(file, buffer, isWindows: true);
      final contents = await file.readAsString();

      expect(contents.startsWith('\uFEFF'), isTrue);
      expect(contents, '\uFEFFa,b\r\nc,d');

      await dir.delete(recursive: true);
    });

    test('writes LF without BOM on non-Windows', () async {
      final dir = await Directory.systemTemp.createTemp('csv_io_test_');
      final file = File('${dir.path}/out.csv');
      final buffer = StringBuffer()
        ..writeln('a,b')
        ..write('c,d');

      await writeCsv(file, buffer, isWindows: false);
      final contents = await file.readAsString();

      expect(contents.startsWith('\uFEFF'), isFalse);
      expect(contents, 'a,b\nc,d');

      await dir.delete(recursive: true);
    });
  });
}

