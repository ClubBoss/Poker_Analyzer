import 'dart:convert';
import 'dart:io';

import '../../lib/cross/hash32.dart';

void main(List<String> args) {
  String? bundle;
  var format = 'compact';

  for (final arg in args) {
    if (arg.startsWith('--bundle=')) {
      bundle = arg.substring(9);
    } else if (arg.startsWith('--format=')) {
      final v = arg.substring(9);
      if (v == 'compact' || v == 'pretty') {
        format = v;
      } else {
        _usage();
      }
    } else {
      _usage();
    }
  }

  if (bundle == null || bundle.isEmpty) {
    _usage();
  }

  final dir = Directory(bundle);
  if (!dir.existsSync()) {
    _fail('missing bundle dir');
  }

  final indexFile = File(_join(bundle!, 'bundle_index.json'));
  final feedFile = File(_join(bundle, 'feed.json'));
  if (!indexFile.existsSync()) {
    _fail('missing bundle_index.json');
  }
  if (!feedFile.existsSync()) {
    _fail('missing feed.json');
  }

  Map<String, dynamic> readJson(File f) {
    try {
      final txt = f.readAsStringSync();
      final data = jsonDecode(txt);
      if (data is Map<String, dynamic>) return data;
    } catch (_) {}
    _fail('malformed json: ${f.path}');
  }

  readJson(feedFile);
  final index = readJson(indexFile);
  final rawFiles = index['files'];
  if (rawFiles is! List) {
    _fail('invalid bundle_index.json');
  }

  final files = <Map<String, dynamic>>[];
  var totalFiles = 0;
  var totalBytes = 0;
  var totalL2 = 0;
  var totalL3 = 0;
  var totalL4 = 0;

  for (final raw in rawFiles) {
    if (raw is! Map<String, dynamic>) {
      _fail('invalid file entry');
    }
    final dst = raw['dst'];
    final kind = raw['kind'];
    if (dst is! String || kind is! String) {
      _fail('invalid file entry');
    }
    final file = File(_join(bundle, dst));
    if (!file.existsSync()) {
      _fail('missing file: $dst');
    }
    final h32 = fnv32HexOfFile(file);
    final length = file.lengthSync();
    int count;
    try {
      final data = jsonDecode(file.readAsStringSync());
      if (kind == 'l2_session') {
        final items = data is Map && data['items'] is List
            ? data['items'] as List
            : const [];
        count = items.length;
        totalL2 += count;
      } else if (kind == 'l3_session') {
        if (data is Map &&
            data['inlineItems'] is List &&
            (data['inlineItems'] as List).isNotEmpty) {
          count = (data['inlineItems'] as List).length;
        } else {
          final items = data is Map && data['items'] is List
              ? data['items'] as List
              : const [];
          count = items.length;
        }
        totalL3 += count;
      } else {
        final items = data is Map && data['items'] is List
            ? data['items'] as List
            : const [];
        count = items.length;
        totalL4 += count;
      }
    } catch (_) {
      _fail('malformed json: $dst');
    }
    files.add({
      'dst': dst,
      'bytes': length,
      'h32': h32,
      'kind': kind,
      'count': count
    });
    totalFiles++;
    totalBytes += length;
  }

  final checks = {
    'version': 'v1',
    'bundle': dir.path,
    'files': files,
    'summary': {
      'files': totalFiles,
      'bytes': totalBytes,
      'l2': totalL2,
      'l3': totalL3,
      'l4': totalL4,
    }
  };
  final encoder = format == 'pretty'
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();
  File(_join(bundle, 'bundle_checks_v1.json'))
      .writeAsStringSync(encoder.convert(checks));

  stdout.writeln(
    'verify ok: files=$totalFiles bytes=$totalBytes l2=$totalL2 l3=$totalL3 l4=$totalL4 checks=bundle_checks_v1.json',
  );
}

String _join(String a, String b) {
  return a.endsWith(Platform.pathSeparator)
      ? '$a$b'
      : '$a${Platform.pathSeparator}$b';
}

void _usage() {
  stdout.writeln('usage: --bundle DIR [--format compact|pretty]');
  exit(2);
}

void _fail(String msg) {
  stdout.writeln('verify failed: $msg');
  exit(2);
}
