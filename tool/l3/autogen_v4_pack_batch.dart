import 'dart:io';

import 'package:poker_analyzer/l3/autogen_v4/board_street_generator.dart';
import 'package:poker_analyzer/l3/autogen_v4/pack_fs.dart';
import 'package:poker_analyzer/l3/autogen_v4/spot_pack.dart';

void main(List<String> args) {
  String? seedsStr;
  String? rangeStr;
  var countStr = '40';
  var preset = 'mvs';
  var format = 'compact';
  var outStr = 'out/l3_packs';
  var overwrite = false;

  for (final arg in args) {
    if (arg == '--overwrite') {
      overwrite = true;
      continue;
    }
    if (!arg.startsWith('--')) {
      _usage();
      exit(2);
    }
    final eq = arg.indexOf('=');
    if (eq == -1) {
      _usage();
      exit(2);
    }
    final name = arg.substring(2, eq);
    final value = arg.substring(eq + 1);
    switch (name) {
      case 'seeds':
        seedsStr = value;
        break;
      case 'range':
        rangeStr = value;
        break;
      case 'count':
        countStr = value;
        break;
      case 'preset':
        preset = value;
        break;
      case 'format':
        format = value;
        break;
      case 'out':
        outStr = value;
        break;
      case 'overwrite':
        if (value == 'true') {
          overwrite = true;
        } else if (value == 'false') {
          overwrite = false;
        } else {
          _usage();
          exit(2);
        }
        break;
      default:
        _usage();
        exit(2);
    }
  }

  if ((seedsStr == null && rangeStr == null) ||
      (seedsStr != null && rangeStr != null)) {
    _usage();
    exit(2);
  }

  final count = int.tryParse(countStr);
  if (count == null ||
      preset != 'mvs' ||
      (format != 'compact' && format != 'pretty')) {
    _usage();
    exit(2);
  }

  final seeds = <int>[];
  if (seedsStr != null) {
    for (final s in seedsStr.split(',')) {
      final v = int.tryParse(s);
      if (v == null) {
        _usage();
        exit(2);
      }
      seeds.add(v);
    }
  } else {
    final parts = rangeStr!.split('-');
    if (parts.length != 2) {
      _usage();
      exit(2);
    }
    final start = int.tryParse(parts[0]);
    final end = int.tryParse(parts[1]);
    if (start == null || end == null || end < start) {
      _usage();
      exit(2);
    }
    for (var i = start; i <= end; i++) {
      seeds.add(i);
    }
  }

  final outDir = Directory(outStr);
  outDir.createSync(recursive: true);

  // Pre-check for existing files when overwrite is false.
  for (final seed in seeds) {
    final name = packFileName(
      seed: seed,
      count: count,
      preset: preset,
      version: 'v1',
    );
    final file = File('${outDir.path}/$name');
    if (file.existsSync() && !overwrite) {
      stderr.writeln('refusing to overwrite ${file.path}');
      exit(2);
    }
  }

  const mix = TargetMix.mvsDefault();
  final indexFile = File('${outDir.path}/pack_index.json');
  final index = PackIndex.loadIndex(indexFile);

  for (final seed in seeds) {
    final pack = buildSpotPack(seed: seed, count: count, mix: mix);
    final file = writePackFile(
      pack,
      outDir: outDir,
      preset: preset,
      format: format,
    );
    final bytes = file.readAsBytesSync();
    final h32 = h32Hex(bytes);
    final ih10 = itemsHash10(pack.items);
    final entry = PackIndexEntry(
      filename: file.uri.pathSegments.last,
      seed: seed,
      count: count,
      preset: preset,
      format: format,
      version: pack.version,
      bytes: bytes.length,
      h32: h32,
      itemsHash10: ih10,
    );
    index.entries.removeWhere((e) => e.filename == entry.filename);
    index.entries.add(entry);
    stdout.writeln(
      'wrote filename=${entry.filename} bytes=${entry.bytes} h32=${entry.h32} itemsHash10=${entry.itemsHash10}',
    );
  }

  index.saveIndex(indexFile);
}

void _usage() {
  stdout.writeln(
    'usage: --seeds=a,b,c | --range=start-end --count=N [--preset mvs] [--format compact|pretty] [--out dir] [--overwrite]',
  );
}
