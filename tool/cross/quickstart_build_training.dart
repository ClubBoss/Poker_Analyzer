import 'dart:io';

void main(List<String> args) {
  var seedBase = 2025;
  var l2PerKind = 20;
  var l3PerPack = 20;
  var l3MaxPacks = 3;
  var l4PerSeed = 20;
  var outSessions = 'out';
  var outFeed = _join('out', _join('feed', 'feed_v1.json'));
  var bundle = _join('dist', 'training_v1');
  var overwrite = false;
  var format = 'compact';

  for (final arg in args) {
    if (arg.startsWith('--seed-base=')) {
      final v = int.tryParse(arg.substring(12));
      if (v == null) _usage();
      seedBase = v ?? seedBase;
    } else if (arg.startsWith('--l2-per-kind=')) {
      final v = int.tryParse(arg.substring(15));
      if (v == null) _usage();
      l2PerKind = v ?? l2PerKind;
    } else if (arg.startsWith('--l3-per-pack=')) {
      final v = int.tryParse(arg.substring(14));
      if (v == null) _usage();
      l3PerPack = v ?? l3PerPack;
    } else if (arg.startsWith('--l3-max-packs=')) {
      final v = int.tryParse(arg.substring(15));
      if (v == null) _usage();
      l3MaxPacks = v ?? l3MaxPacks;
    } else if (arg.startsWith('--l4-per-seed=')) {
      final v = int.tryParse(arg.substring(14));
      if (v == null) _usage();
      l4PerSeed = v ?? l4PerSeed;
    } else if (arg.startsWith('--out-sessions=')) {
      outSessions = arg.substring(15);
    } else if (arg.startsWith('--out-feed=')) {
      outFeed = arg.substring(11);
    } else if (arg.startsWith('--bundle=')) {
      bundle = arg.substring(9);
    } else if (arg == '--overwrite') {
      overwrite = true;
    } else if (arg.startsWith('--format=')) {
      final v = arg.substring(9);
      if (v != 'compact' && v != 'pretty') {
        _usage();
      }
      format = v;
    } else {
      _usage();
    }
  }

  final l2Seed = seedBase + 11;
  final l3Seed = seedBase + 22; // computed but not used
  final l4Seed = seedBase + 33;

  final l2Dir = _join(outSessions, 'l2_sessions');
  final l3Dir = _join(outSessions, 'l3_sessions');
  final l4Dir = _join(outSessions, 'l4_sessions');
  Directory(l2Dir).createSync(recursive: true);
  Directory(l3Dir).createSync(recursive: true);
  Directory(l4Dir).createSync(recursive: true);

  final l2Name = 'session_l2_v1_seed${l2Seed}_k${l2PerKind}.json';
  final l3Name = 'session_l3_v1_mvs_p${l3PerPack}_k${l3MaxPacks}.json';
  final l4Name = 'session_icm_v1_mvs_k1_n${l4PerSeed}.json';

  final l2Path = _join(l2Dir, l2Name);
  final l3Path = _join(l3Dir, l3Name);
  final l4Path = _join(l4Dir, l4Name);
  _checkFile(l2Path, overwrite);
  _checkFile(l3Path, overwrite);
  _checkFile(l4Path, overwrite);

  _run([
    'dart',
    'run',
    'tool/l2/autogen_v1_session_build.dart',
    '--seed=$l2Seed',
    '--per-kind=$l2PerKind',
    '--format',
    format,
    '--out',
    l2Dir,
    '--name',
    l2Name,
  ]);

  const l3Index = 'out/l3_packs/pack_index.json';
  if (!File(l3Index).existsSync()) {
    stdout.writeln('missing L3 pack_index.json; run batch pack CLI first');
    exit(2);
  }
  _run([
    'dart',
    'run',
    'tool/l3/autogen_v4_session_build.dart',
    '--index',
    l3Index,
    '--filter-preset',
    'mvs',
    '--per-pack',
    '$l3PerPack',
    '--max-packs',
    '$l3MaxPacks',
    '--mode',
    'refs',
    '--manifest-format',
    'compact',
    '--out',
    l3Dir,
    '--name',
    l3Name,
  ]);

  _run([
    'dart',
    'run',
    'tool/l4/icm_v1_session_build.dart',
    '--seeds=$l4Seed',
    '--per-seed=$l4PerSeed',
    '--format',
    format,
    '--out',
    l4Dir,
    '--name',
    l4Name,
  ]);

  final feedDir = _dirname(outFeed);
  final feedName = _basename(outFeed);
  Directory(feedDir).createSync(recursive: true);
  _checkFile(_join(feedDir, feedName), overwrite);
  _run([
    'dart',
    'run',
    'tool/cross/build_feed.dart',
    '--l2=$l2Path',
    '--l3=$l3Path',
    '--l4=$l4Path',
    '--format',
    format,
    '--out',
    feedDir,
    '--name',
    feedName,
  ]);

  final bundleDir = Directory(bundle);
  if (bundleDir.existsSync()) {
    if (!overwrite) {
      stdout.writeln('refusing to overwrite existing bundle dir: $bundle');
      exit(2);
    }
    bundleDir.deleteSync(recursive: true);
  }
  Directory(bundleDir.parent.path).createSync(recursive: true);
  final packArgs = [
    'dart',
    'run',
    'tool/cross/pack_training_library.dart',
    '--feed=$outFeed',
    '--out=$bundle',
    '--layout',
    'bykind',
    '--format',
    format,
  ];
  if (overwrite) {
    packArgs.add('--overwrite');
  }
  _run(packArgs);

  stdout.writeln('quickstart ok: l2=1 l3=1 l4=1 feed=$outFeed bundle=$bundle');
}

void _run(List<String> cmd) {
  final res = Process.runSync(cmd[0], cmd.sublist(1));
  stdout.write(res.stdout);
  stderr.write(res.stderr);
  if (res.exitCode != 0) {
    stderr.writeln('failed: ${cmd.join(' ')}');
    exit(2);
  }
}

void _checkFile(String path, bool overwrite) {
  final f = File(path);
  if (f.existsSync() && !overwrite) {
    stdout.writeln('refusing to overwrite existing file: $path');
    exit(2);
  }
}

String _join(String a, String b) {
  return a.endsWith(Platform.pathSeparator)
      ? '$a$b'
      : '$a${Platform.pathSeparator}$b';
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

void _usage() {
  stdout.writeln(
      'usage: [--seed-base N] [--l2-per-kind N] [--l3-per-pack N] [--l3-max-packs K] [--l4-per-seed N] [--out-sessions DIR] [--out-feed FILE] [--bundle DIR] [--overwrite] [--format compact|pretty]');
  exit(2);
}
