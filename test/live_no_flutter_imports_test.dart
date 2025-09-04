// ASCII-only; pure Dart test guard for Live layer purity

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('live layer purity', () {
    test('no Flutter imports and ASCII-only files', () {
      final root = Directory('lib/live');
      expect(
        root.existsSync(),
        isTrue,
        reason: 'lib/live directory must exist',
      );

      final violations = <String>[];

      for (final entity in root.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.dart')) continue;

        final path = entity.path;
        final bytes = entity.readAsBytesSync();

        // 1) ASCII-only bytes check
        for (int i = 0; i < bytes.length; i++) {
          final b = bytes[i];
          if (b > 0x7F) {
            final info = _lineInfoForIndex(bytes, i);
            violations.add(
              path +
                  ':' +
                  info.lineNumber.toString() +
                  ': non-ASCII byte 0x' +
                  b.toRadixString(16).padLeft(2, '0') +
                  ' in: ' +
                  info.printableLine,
            );
          }
        }

        // 2) No Flutter imports
        violations.addAll(
          _scanForAsciiSubstring(
            bytes: bytes,
            path: path,
            needle: 'package:flutter/',
            label: 'disallowed import',
          ),
        );

        // 3) No flutter_test usage
        violations.addAll(
          _scanForAsciiSubstring(
            bytes: bytes,
            path: path,
            needle: 'flutter_test',
            label: 'disallowed test import',
          ),
        );
      }

      if (violations.isNotEmpty) {
        // Print for developer convenience.
        for (final v in violations) {
          // ignore: avoid_print
          print(v);
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Live layer must be pure-Dart ASCII with no Flutter imports.',
      );
    });
  });
}

class _LineInfo {
  final int lineNumber; // 1-based
  final String printableLine;
  _LineInfo(this.lineNumber, this.printableLine);
}

_LineInfo _lineInfoForIndex(List<int> bytes, int index) {
  // Find start of line (previous \n)
  int start = index;
  while (start > 0 && bytes[start - 1] != 0x0A) {
    start--;
  }
  // Find end of line (next \n)
  int end = index;
  while (end < bytes.length && bytes[end] != 0x0A) {
    end++;
  }

  // Compute line number: count \n up to start.
  int line = 1;
  for (int i = 0; i < start; i++) {
    if (bytes[i] == 0x0A) line++;
  }

  final lineBytes = bytes.sublist(start, end);
  final printable = String.fromCharCodes(
    lineBytes.map((b) => b <= 0x7F ? b : 0x3F), // replace non-ASCII with '?'
  ).trimRight();
  return _LineInfo(line, printable);
}

List<String> _scanForAsciiSubstring({
  required List<int> bytes,
  required String path,
  required String needle,
  required String label,
}) {
  final result = <String>[];
  final n = needle.codeUnits; // ASCII-only needle assumed
  int i = 0;
  while (i <= bytes.length - n.length) {
    bool match = true;
    for (int j = 0; j < n.length; j++) {
      if (bytes[i + j] != n[j]) {
        match = false;
        break;
      }
    }
    if (match) {
      final info = _lineInfoForIndex(bytes, i);
      result.add(
        path +
            ':' +
            info.lineNumber.toString() +
            ': ' +
            label +
            ' "' +
            needle +
            '" in: ' +
            info.printableLine,
      );
      i += n.length;
    } else {
      i++;
    }
  }
  return result;
}
