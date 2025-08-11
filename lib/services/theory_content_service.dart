import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/theory_content_block.dart';

class TheoryContentService {
  TheoryContentService._();
  static final TheoryContentService instance = TheoryContentService._();

  static const String _dir = 'assets/theory_blocks/';

  final Map<String, Map<String, TheoryContentBlock>> _localized = {};
  final List<TheoryContentBlock> _blocks = [];

  List<TheoryContentBlock> get all => List.unmodifiable(_blocks);

  TheoryContentBlock? get(String id, {String? locale}) {
    locale ??= PlatformDispatcher.instance.locale.languageCode;
    final byId = _localized[id];
    if (byId == null) return null;
    if (byId.containsKey(locale)) {
      return byId[locale];
    }
    return byId[''];
  }

  Future<void> loadAll() async {
    if (_blocks.isNotEmpty) return;
    await reload();
  }

  Future<void> reload() async {
    _blocks.clear();
    _localized.clear();
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
        .toList();
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final block = TheoryContentBlock.fromYaml(
          Map<String, dynamic>.from(map),
        );
        if (block.id.isEmpty) continue;
        _blocks.add(block);
        final locale = _extractLocale(path);
        final mapByLocale = _localized.putIfAbsent(block.id, () => {});
        mapByLocale.putIfAbsent(locale, () => block);
      } catch (_) {}
    }
  }

  Future<void> addOrUpdate(TheoryContentBlock block) async {
    final idx = _blocks.indexWhere((b) => b.id == block.id);
    if (idx >= 0) {
      _blocks[idx] = block;
    } else {
      _blocks.add(block);
    }
    final locale = PlatformDispatcher.instance.locale.languageCode;
    final mapByLocale = _localized.putIfAbsent(block.id, () => {});
    mapByLocale[locale ?? ''] = block;
  }

  Future<void> delete(String id) async {
    _blocks.removeWhere((b) => b.id == id);
    _localized.remove(id);
  }

  String _extractLocale(String path) {
    final name = path.split('/').last;
    final m = RegExp(r'^(.+)_([a-z]{2})\\.yaml\$').firstMatch(name);
    if (m != null) {
      return m.group(2)!;
    }
    return '';
  }
}
