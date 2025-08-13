import 'dart:convert';
import 'dart:io';

class _Counts {
  int packs = 0;
  int spots = 0;
  void add(int spotCount) {
    packs += 1;
    spots += spotCount;
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final map = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--') && i + 1 < args.length) {
      map[arg.substring(2)] = args[++i];
    }
  }
  return map;
}

Future<void> main(List<String> args) async {
  final argMap = _parseArgs(args);
  final rootsArg = argMap['roots'] ?? 'assets/packs/l2,assets/packs/l3';
  final roots = rootsArg.split(',').where((e) => e.isNotEmpty).toList();
  final outFile = File(argMap['out'] ?? 'build/reports/packs_manifest.json');
  final mdOutPath = argMap['mdOut'];
  final entries = <Map<String, Object>>[];
  final stageSubtypeStats = <String, Map<String, _Counts>>{};
  var totalSpots = 0;

  final tagLineReg = RegExp(r'-\s*(\S+)');
  final packTagSectionReg = RegExp(
    r'^tags:\n((?:\s+-\s*\S+\n)+)',
    multiLine: true,
  );
  final spotReg = RegExp(r'^\s{2}-\n((?:\s{4}.+\n)+)', multiLine: true);
  final spotTagsReg = RegExp(
    r'^\s{4}tags:\n((?:\s{6}-\s*\S+\n)+)',
    multiLine: true,
  );

  for (final root in roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.yaml'));
    for (final file in files) {
      final raw = await file.readAsString();
      if (!raw.contains('\nspots:')) continue;
      final id =
          RegExp(r'^id:\s*(\S+)', multiLine: true).firstMatch(raw)?.group(1) ??
          '';
      final stageId =
          RegExp(
            r'^stage:\n\s+id:\s*(\S+)',
            multiLine: true,
          ).firstMatch(raw)?.group(1) ??
          'unknown';
      final subtype =
          RegExp(
            r'^subtype:\s*(\S+)',
            multiLine: true,
          ).firstMatch(raw)?.group(1) ??
          'unknown';
      final street =
          RegExp(
            r'^street:\s*(\S+)',
            multiLine: true,
          ).firstMatch(raw)?.group(1) ??
          'unknown';

      final tagsHistogram = <String, int>{};
      final textureHistogram = <String, int>{
        'monotone': 0,
        'twoTone': 0,
        'rainbow': 0,
      };

      final packTagSection = packTagSectionReg.firstMatch(raw);
      if (packTagSection != null) {
        final lines = packTagSection.group(1)!.trim().split('\n');
        for (final line in lines) {
          final tag = tagLineReg.firstMatch(line)?.group(1);
          if (tag != null) {
            tagsHistogram[tag] = (tagsHistogram[tag] ?? 0) + 1;
            if (textureHistogram.containsKey(tag)) {
              textureHistogram[tag] = textureHistogram[tag]! + 1;
            }
          }
        }
      }

      final spotMatches = spotReg.allMatches(raw).toList();
      final spotsCount = spotMatches.length;
      for (final match in spotMatches) {
        final spotContent = match.group(1)!;
        final tagSection = spotTagsReg.firstMatch(spotContent);
        if (tagSection != null) {
          final lines = tagSection.group(1)!.trim().split('\n');
          for (final line in lines) {
            final tag = tagLineReg.firstMatch(line)?.group(1);
            if (tag != null) {
              tagsHistogram[tag] = (tagsHistogram[tag] ?? 0) + 1;
              if (textureHistogram.containsKey(tag)) {
                textureHistogram[tag] = textureHistogram[tag]! + 1;
              }
            }
          }
        }
      }

      totalSpots += spotsCount;
      entries.add({
        'id': id,
        'stage': {'id': stageId},
        'subtype': subtype,
        'street': street,
        'file': file.path,
        'spotsCount': spotsCount,
        'tagsHistogram': tagsHistogram,
        'textureHistogram': textureHistogram,
      });
      final stageMap = stageSubtypeStats.putIfAbsent(
        stageId,
        () => <String, _Counts>{},
      );
      stageMap.putIfAbsent(subtype, () => _Counts()).add(spotsCount);
    }
  }

  entries.sort((a, b) {
    final s = (a['stage'] as Map)['id'].toString().compareTo(
      (b['stage'] as Map)['id'].toString(),
    );
    if (s != 0) return s;
    final st = a['subtype'].toString().compareTo(b['subtype'].toString());
    if (st != 0) return st;
    return a['id'].toString().compareTo(b['id'].toString());
  });

  if (!outFile.parent.existsSync()) {
    outFile.parent.createSync(recursive: true);
  }
  final manifest = {
    'totalPacks': entries.length,
    'totalSpots': totalSpots,
    'packs': entries,
  };
  await outFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest),
  );

  if (mdOutPath != null) {
    final mdFile = File(mdOutPath);
    if (!mdFile.parent.existsSync()) {
      mdFile.parent.createSync(recursive: true);
    }
    final buffer = StringBuffer();
    buffer.writeln('# Packs Manifest');
    buffer.writeln();
    buffer.writeln('- total packs: ${entries.length}');
    buffer.writeln('- total spots: $totalSpots');
    buffer.writeln();
    buffer.writeln('## By stage/subtype');
    final stageKeys = stageSubtypeStats.keys.toList()..sort();
    for (final stage in stageKeys) {
      buffer.writeln('- $stage');
      final sub = stageSubtypeStats[stage]!;
      final subKeys = sub.keys.toList()..sort();
      for (final st in subKeys) {
        final c = sub[st]!;
        buffer.writeln('  - $st: ${c.packs} packs, ${c.spots} spots');
      }
    }
    await mdFile.writeAsString(buffer.toString());
  }

  print('packs: ${entries.length}, spots: $totalSpots');
}
