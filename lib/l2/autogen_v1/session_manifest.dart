import 'dart:convert';

class L2SessionItem {
  final String kind;
  final String hand;
  final String pos;
  final String stack;
  final String action;
  final String? vsPos;
  final String? limpers;
  const L2SessionItem({
    required this.kind,
    required this.hand,
    required this.pos,
    required this.stack,
    required this.action,
    this.vsPos,
    this.limpers,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'kind': kind,
      'hand': hand,
      'pos': pos,
      'stack': stack,
      'action': action,
    };
    if (vsPos != null) map['vsPos'] = vsPos;
    if (limpers != null) map['limpers'] = limpers;
    return map;
  }
}

class L2SessionManifest {
  final String version;
  final int baseSeed;
  final int perKind;
  final List<String> kinds;
  final List<L2SessionItem> items;
  const L2SessionManifest({
    required this.version,
    required this.baseSeed,
    required this.perKind,
    required this.kinds,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'baseSeed': baseSeed,
    'perKind': perKind,
    'kinds': kinds,
    'items': [for (final i in items) i.toJson()],
  };
}

String encodeL2ManifestCompact(L2SessionManifest m) => jsonEncode(m.toJson());

String encodeL2ManifestPretty(L2SessionManifest m) =>
    const JsonEncoder.withIndent('  ').convert(m.toJson());
