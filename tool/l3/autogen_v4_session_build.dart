import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:poker_analyzer/l3/autogen_v4/pack_fs.dart';
import 'package:poker_analyzer/l3/autogen_v4/session_manifest.dart';
import 'package:poker_analyzer/l3/autogen_v4/spot_pack.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('index', defaultsTo: 'out/l3_packs/pack_index.json')
    ..addOption('filter-preset', defaultsTo: 'mvs')
    ..addOption('per-pack', defaultsTo: '20')
    ..addOption('max-packs', defaultsTo: '3')
    ..addOption('mode', defaultsTo: 'refs')
    ..addOption('manifest-format', defaultsTo: 'compact')
    ..addOption('out', defaultsTo: 'out/l3_sessions')
    ..addOption('name');

  ArgResults res;
  try {
    res = parser.parse(args);
  } catch (_) {
    _usage();
    exit(2);
  }

  final indexPath = res['index'] as String?;
  final preset = res['filter-preset'] as String?;
  final perPackStr = res['per-pack'] as String?;
  final maxPacksStr = res['max-packs'] as String?;
  final modeStr = res['mode'] as String?;
  final format = res['manifest-format'] as String?;
  final outDirStr = res['out'] as String?;
  var name = res['name'] as String?;

  final perPack = int.tryParse(perPackStr ?? '');
  final maxPacks = int.tryParse(maxPacksStr ?? '');
  final mode = modeStr == 'inline'
      ? RefMode.inline
      : modeStr == 'refs'
      ? RefMode.refs
      : null;
  if (indexPath == null ||
      preset == null ||
      perPack == null ||
      maxPacks == null ||
      mode == null ||
      (format != 'compact' && format != 'pretty') ||
      outDirStr == null) {
    _usage();
    exit(2);
  }

  name ??= 'session_v1_\${preset}_p\${perPack}_k\${maxPacks}.json';

  final indexFile = File(indexPath);
  final index = PackIndex.loadIndex(indexFile);
  final entries =
      index.entries
          .where(
            (e) =>
                e.preset == preset &&
                (e.format == 'compact' || e.format == 'pretty'),
          )
          .toList()
        ..sort((a, b) => a.filename.compareTo(b.filename));

  final files = <String>[];
  final itemRefs = <SessionItemRef>[];
  final inlineItems = <SpotDTO>[];
  var total = 0;

  for (final entry in entries.take(maxPacks)) {
    files.add(entry.filename);
    final packPath = '${indexFile.parent.path}/${entry.filename}';
    final content = File(packPath).readAsStringSync();
    final j = jsonDecode(content) as Map<String, dynamic>;
    final items = (j['items'] as List<dynamic>).cast<Map<String, dynamic>>();
    final take = perPack < items.length ? perPack : items.length;
    for (var i = 0; i < take; i++) {
      final it = items[i];
      if (mode == RefMode.refs) {
        itemRefs.add(SessionItemRef(file: entry.filename, index: i));
      } else {
        inlineItems.add(
          SpotDTO(
            board: it['board'] as String,
            street: it['street'] as String,
            spr: it['spr'] as String,
            pos: it['pos'] as String,
          ),
        );
      }
      total++;
    }
  }

  final manifest = SessionManifest(
    version: 'v1',
    preset: preset,
    perPack: perPack,
    total: total,
    mode: mode,
    files: files,
    items: itemRefs,
    inlineItems: mode == RefMode.inline ? inlineItems : null,
  );

  final outDir = Directory(outDirStr);
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/$name');
  final out = format == 'pretty'
      ? encodeManifestPretty(manifest)
      : encodeManifestCompact(manifest);
  outFile.writeAsStringSync(out);

  stdout.writeln(
    'wrote session name=$name packs=\${files.length} perPack=$perPack total=$total mode=\${mode.name}',
  );
}

void _usage() {
  stdout.writeln(
    'usage: --index=path [--filter-preset mvs] [--per-pack N] [--max-packs K] [--mode refs|inline] [--manifest-format compact|pretty] [--out dir] [--name file]',
  );
}
