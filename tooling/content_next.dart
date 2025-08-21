import 'dart:io';

import 'curriculum_ids.dart';

bool _hasContent(String id) {
  final base = 'content/$id/v1';
  return File('$base/theory.md').existsSync() &&
      File('$base/demos.jsonl').existsSync() &&
      File('$base/drills.jsonl').existsSync();
}

void main(List<String> args) {
  final strict = args.contains('--strict');
  final ids = kCurriculumIds;
  var prefix = 0;
  String? next;
  for (final id in ids) {
    if (_hasContent(id)) {
      prefix++;
    } else {
      next = id;
      break;
    }
  }
  final missing = next == null ? <String>[] : ids.sublist(prefix);
  print('CONTENT_DONE_PREFIX=$prefix');
  print('CONTENT_NEXT=${next ?? 'ALL DONE'}');
  print('CONTENT_MISSING:${missing.join(',')}');
  if (strict && next != null) {
    exitCode = 1;
  }
}
