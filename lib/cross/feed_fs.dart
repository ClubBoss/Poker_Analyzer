import 'dart:convert';
import 'dart:io';

class FeedRef {
  final String kind;
  final String path;
  final int count;

  const FeedRef({required this.kind, required this.path, required this.count});
}

List<FeedRef> readFeedRefs(File feedFile) {
  final data = jsonDecode(feedFile.readAsStringSync());
  final items = data is Map && data['items'] is List
      ? data['items'] as List
      : <dynamic>[];
  final refs = <FeedRef>[];
  for (final item in items) {
    if (item is Map) {
      final kind = item['kind']?.toString() ?? '';
      final file = item['file']?.toString() ?? '';
      final countValue = item['count'];
      var count = 0;
      if (countValue is int) {
        count = countValue;
      } else if (countValue is num) {
        count = countValue.toInt();
      }
      refs.add(FeedRef(kind: kind, path: file, count: count));
    }
  }
  return refs;
}

String normFileName(String original) {
  var base = original;
  final idx1 = base.lastIndexOf('/');
  final idx2 = base.lastIndexOf('\\');
  final idx = idx1 > idx2 ? idx1 : idx2;
  if (idx != -1) {
    base = base.substring(idx + 1);
  }
  final buffer = StringBuffer();
  for (final code in base.codeUnits) {
    final ok =
        (code >= 0x30 && code <= 0x39) ||
        (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        code == 0x2D ||
        code == 0x5F ||
        code == 0x2E;
    buffer.writeCharCode(ok ? code : 0x5F);
  }
  final result = buffer.toString();
  return result.isEmpty ? '_' : result;
}

void copyFileTo(File src, File dst) {
  dst.parent.createSync(recursive: true);
  dst.writeAsBytesSync(src.readAsBytesSync());
}
