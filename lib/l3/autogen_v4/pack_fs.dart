// File system helpers for writing and indexing deterministic L3 spot packs.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'spot_pack.dart';

String packFileName({
  required int seed,
  required int count,
  required String preset,
  required String version,
}) =>
    'l3_pack_\${version}_seed\${seed}*c\${count}*\${preset}.json';

String h32Hex(Uint8List bytes) {
  const offset = 0x811c9dc5;
  const prime = 0x01000193;
  var h = offset;
  for (final b in bytes) {
    h = h ^ b;
    h = (h * prime) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

String itemsHash10(List<SpotDTO> items) {
  final joined = items.take(10).map((e) => e.toString()).join('|');
  final bytes = Uint8List.fromList(utf8.encode(joined));
  return h32Hex(bytes);
}

File writePackFile(
  SpotPack p, {
  required Directory outDir,
  required String preset,
  required String format,
}) {
  final filename = packFileName(
    seed: p.seed,
    count: p.count,
    preset: preset,
    version: p.version,
  );
  final file = File('${outDir.path}/$filename');
  final content =
      format == 'pretty' ? encodeSpotPackPretty(p) : encodeSpotPackCompact(p);
  file.writeAsStringSync(content);
  return file;
}

class PackIndexEntry {
  final String filename;
  final int seed;
  final int count;
  final String preset;
  final String format;
  final String version;
  final int bytes;
  final String h32;
  final String itemsHash10;

  PackIndexEntry({
    required this.filename,
    required this.seed,
    required this.count,
    required this.preset,
    required this.format,
    required this.version,
    required this.bytes,
    required this.h32,
    required this.itemsHash10,
  });

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'seed': seed,
        'count': count,
        'preset': preset,
        'format': format,
        'version': version,
        'bytes': bytes,
        'h32': h32,
        'itemsHash10': itemsHash10,
      };

  factory PackIndexEntry.fromJson(Map<String, dynamic> j) => PackIndexEntry(
        filename: j['filename'] as String,
        seed: j['seed'] as int,
        count: j['count'] as int,
        preset: j['preset'] as String,
        format: j['format'] as String,
        version: j['version'] as String,
        bytes: j['bytes'] as int,
        h32: j['h32'] as String,
        itemsHash10: j['itemsHash10'] as String,
      );
}

class PackIndex {
  final List<PackIndexEntry> entries;

  PackIndex({required this.entries});

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  static PackIndex loadIndex(File f) {
    if (!f.existsSync()) {
      return PackIndex(entries: []);
    }
    final content = f.readAsStringSync();
    final j = jsonDecode(content) as Map<String, dynamic>;
    final list = (j['entries'] as List<dynamic>)
        .map((e) => PackIndexEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return PackIndex(entries: list);
  }

  void saveIndex(File f) {
    final content = jsonEncode(toJson());
    f.writeAsStringSync(content);
  }
}
