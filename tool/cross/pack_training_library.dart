import 'dart:convert';
import 'dart:io';

import '../../lib/cross/feed.dart';
import '../../lib/cross/feed_fs.dart';

void main(List<String> args) {
  String? feedPath;
  var outDir = 'dist/training_v1';
  var layout = 'flat';
  var overwrite = false;
  var format = 'compact';

  for (final arg in args) {
    if (arg.startsWith('--feed=')) {
      feedPath = arg.substring(7);
    } else if (arg.startsWith('--out=')) {
      outDir = arg.substring(6);
    } else if (arg.startsWith('--layout=')) {
      final v = arg.substring(9);
      if (v == 'flat' || v == 'bykind') {
        layout = v;
      } else {
        _usage();
      }
    } else if (arg == '--overwrite') {
      overwrite = true;
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

  if (feedPath == null || feedPath.isEmpty) {
    _usage();
  }

  final feedFile = File(feedPath);
  if (!feedFile.existsSync()) {
    stderr.writeln('missing feed: $feedPath');
    exit(2);
  }

  final refs = readFeedRefs(feedFile);

  final out = Directory(outDir);
  if (out.existsSync()) {
    if (out.listSync().isNotEmpty) {
      if (!overwrite) {
        stdout.writeln('refusing to overwrite');
        exit(2);
      }
      out.deleteSync(recursive: true);
      out.createSync(recursive: true);
    }
  } else {
    out.createSync(recursive: true);
  }

  copyFileTo(feedFile, File(_join(outDir, 'feed.json')));

  final files = <Map<String, dynamic>>[];
  var l2 = 0;
  var l3 = 0;
  var l4 = 0;

  for (final ref in refs) {
    final src = File(ref.path);
    if (!src.existsSync()) {
      stderr.writeln('missing file: ${ref.path}');
      exit(2);
    }
    var dstRel = normFileName(ref.path);
    if (layout == 'bykind') {
      dstRel = _join(ref.kind, dstRel);
    }
    final dst = File(_join(outDir, dstRel));
    copyFileTo(src, dst);
    files.add({
      'kind': ref.kind,
      'src': ref.path,
      'dst': dstRel,
      'count': ref.count,
    });
    if (ref.kind == 'l2_session') {
      l2++;
    } else if (ref.kind == 'l3_session') {
      l3++;
    } else if (ref.kind == 'l4_session') {
      l4++;
    }
  }

  final index = {
    'version': 'v1',
    'layout': layout,
    'feed': 'feed.json',
    'files': files,
  };

  final encoder = format == 'pretty'
      ? const JsonEncoder.withIndent('  ')
      : const JsonEncoder();
  File(_join(outDir, 'bundle_index.json'))
      .writeAsStringSync(encoder.convert(index));

  stdout.writeln(
    'packed training_v1 out=$outDir files=${files.length} l2=$l2 l3=$l3 l4=$l4 layout=$layout',
  );
}

String _join(String a, String b) {
  return a.endsWith(Platform.pathSeparator)
      ? '$a$b'
      : '$a${Platform.pathSeparator}$b';
}

void _usage() {
  stdout.writeln(
    'usage: --feed=FILE [--out=DIR] [--layout flat|bykind] [--overwrite] [--format compact|pretty]',
  );
  exit(2);
}
