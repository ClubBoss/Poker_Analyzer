import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/l3/autogen_v4/board_street_generator.dart';
import 'package:poker_analyzer/l3/autogen_v4/pack_fs.dart';
import 'package:poker_analyzer/l3/autogen_v4/spot_pack.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('seeds')
    ..addOption('range')
    ..addOption('count', defaultsTo: '40')
    ..addOption('preset', defaultsTo: 'mvs')
    ..addOption('format', defaultsTo: 'compact')
    ..addOption('out', defaultsTo: 'out/l3_packs')
    ..addFlag('overwrite', defaultsTo: false);

  ArgResults res;
  try {
    res = parser.parse(args);
  } catch (_) {
    _usage();
    exit(2);
  }

  final seedsStr = res['seeds'] as String?;
  final rangeStr = res['range'] as String?;
  if ((seedsStr == null && rangeStr == null) ||
      (seedsStr != null && rangeStr != null)) {
    _usage();
    exit(2);
  }

  final count = int.tryParse(res['count'] as String? ?? '');
  final preset = res['preset'] as String?;
  final format = res['format'] as String?;
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

  final outDir = Directory(res['out'] as String);
  outDir.createSync(recursive: true);
  final overwrite = res['overwrite'] as bool;

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
      preset: preset!,
      format: format!,
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
