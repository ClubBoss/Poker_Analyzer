import 'dart:convert';

class L4IcmSessionItem {
  final String hand;
  final String heroPos;
  final String stackBb;
  final String stacks;
  final String action;

  const L4IcmSessionItem({
    required this.hand,
    required this.heroPos,
    required this.stackBb,
    required this.stacks,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        'hand': hand,
        'heroPos': heroPos,
        'stackBb': stackBb,
        'stacks': stacks,
        'action': action,
      };
}

class L4IcmSessionManifest {
  final String version;
  final String preset;
  final int total;
  final List<int> seeds;
  final int perSeed;
  final List<L4IcmSessionItem> items;

  const L4IcmSessionManifest({
    this.version = 'v1',
    required this.preset,
    required this.total,
    required this.seeds,
    required this.perSeed,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'preset': preset,
        'total': total,
        'seeds': seeds,
        'perSeed': perSeed,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

String encodeIcmManifestCompact(L4IcmSessionManifest m) =>
    jsonEncode(m.toJson());

String encodeIcmManifestPretty(L4IcmSessionManifest m) =>
    const JsonEncoder.withIndent(' ').convert(m.toJson());
