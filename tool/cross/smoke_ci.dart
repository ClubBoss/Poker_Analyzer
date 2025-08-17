import 'dart:io';

void main(List<String> args) {
  String? l2Arg;
  String? l3Arg;
  String? l4Arg;
  var feed = _join('out', _join('feed', 'feed_v1.json'));
  var bundle = _join('dist', 'training_v1');
  var format = 'compact';
  var layout = 'bykind';
  var overwrite = false;

  for (final a in args) {
    if (a.startsWith('--l2=')) {
      l2Arg = a.substring(5);
    } else if (a.startsWith('--l3=')) {
      l3Arg = a.substring(5);
    } else if (a.startsWith('--l4=')) {
      l4Arg = a.substring(5);
    } else if (a.startsWith('--feed=')) {
      feed = a.substring(7);
    } else if (a.startsWith('--bundle=')) {
      bundle = a.substring(9);
    } else if (a.startsWith('--format=')) {
      final v = a.substring(9);
      if (v == 'compact' || v == 'pretty') {
        format = v;
      } else {
        _usage();
      }
    } else if (a.startsWith('--layout=')) {
      final v = a.substring(9);
      if (v == 'flat' || v == 'bykind') {
        layout = v;
      } else {
        _usage();
      }
    } else if (a == '--overwrite') {
      overwrite = true;
    } else {
      _usage();
    }
  }

  final l2 = _splitList(l2Arg);
  final l3 = _splitList(l3Arg);
  final l4 = _splitList(l4Arg);

  if (l2.isEmpty && l3.isEmpty && l4.isEmpty) {
    _usage();
  }

  for (final path in [...l2, ...l3, ...l4]) {
    if (!File(path).existsSync()) {
      stdout.writeln('missing file: $path');
      exit(2);
    }
  }

  final feedDir = _dirname(feed);
  final feedName = _basename(feed);

  _run([
    'dart',
    'run',
    'tool/cross/build_feed.dart',
    if (l2.isNotEmpty) '--l2=${l2.join(',')}',
    if (l3.isNotEmpty) '--l3=${l3.join(',')}',
    if (l4.isNotEmpty) '--l4=${l4.join(',')}',
    '--format=$format',
    '--out=$feedDir',
    '--name=$feedName',
  ]);

  final packArgs = [
    'dart',
    'run',
    'tool/cross/pack_training_library.dart',
    '--feed=$feed',
    '--out=$bundle',
    '--layout=$layout',
    '--format=$format',
  ];
  if (overwrite) {
    packArgs.add('--overwrite');
  }
  _run(packArgs);

  _run([
    'dart',
    'run',
    'tool/cross/verify_training_bundle.dart',
    '--bundle=$bundle',
    '--format=$format',
  ]);

  _run([
    'dart',
    'run',
    'tool/cross/print_feed_summary.dart',
    '--feed=$feed',
  ]);

  stdout.writeln(
      'smoke ok: feed=$feed bundle=$bundle format=$format layout=$layout');
}

List<String> _splitList(String? v) => v == null || v.isEmpty
    ? <String>[]
    : v.split(',').where((e) => e.isNotEmpty).toList();

void _run(List<String> cmd) {
  final res = Process.runSync(cmd[0], cmd.sublist(1));
  stdout.write(res.stdout);
  stderr.write(res.stderr);
  if (res.exitCode != 0) {
    stdout.writeln('failed: ${cmd.join(' ')}');
    exit(2);
  }
}

String _dirname(String path) {
  final sep = Platform.pathSeparator;
  final i = path.lastIndexOf(sep);
  return i == -1 ? '.' : path.substring(0, i);
}

String _basename(String path) {
  final sep = Platform.pathSeparator;
  final i = path.lastIndexOf(sep);
  return i == -1 ? path : path.substring(i + 1);
}

String _join(String a, String b) => a.endsWith(Platform.pathSeparator)
    ? '$a$b'
    : '$a${Platform.pathSeparator}$b';

Never _usage() {
  stdout.writeln(
      'usage: --l2 a.json[,..] [--l3 c.json[,..]] [--l4 e.json[,..]] [--feed FILE] [--bundle DIR] [--format compact|pretty] [--layout flat|bykind] [--overwrite]');
  exit(2);
}
