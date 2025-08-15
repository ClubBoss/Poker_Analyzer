// Deterministic session manifest structures for L3.
import 'dart:convert';

import 'spot_pack.dart';

enum RefMode { refs, inline }

class SessionItemRef {
  final String file;
  final int index;

  const SessionItemRef({required this.file, required this.index});

  Map<String, dynamic> toJson() => {
        'file': file,
        'index': index,
      };
}

class SessionManifest {
  final String version;
  final String preset;
  final int perPack;
  final int total;
  final RefMode mode;
  final List<String> files;
  final List<SessionItemRef> items;
  final List<SpotDTO>? inlineItems;

  const SessionManifest({
    required this.version,
    required this.preset,
    required this.perPack,
    required this.total,
    required this.mode,
    required this.files,
    required this.items,
    this.inlineItems,
  });

  Map<String, dynamic> toJson() {
    final m = {
      'version': version,
      'preset': preset,
      'perPack': perPack,
      'total': total,
      'mode': mode.name,
      'files': files,
      'items': items.map((e) => e.toJson()).toList(),
    };
    if (inlineItems != null) {
      m['inlineItems'] = inlineItems!.map((e) => e.toJson()).toList();
    }
    return m;
  }
}

String encodeManifestCompact(SessionManifest m) => jsonEncode(m.toJson());

String encodeManifestPretty(SessionManifest m) =>
    const JsonEncoder.withIndent(' ').convert(m.toJson());

