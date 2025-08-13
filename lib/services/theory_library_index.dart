import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import 'inline_pack_theory_clusterer.dart';

/// Loads theory resources from [assetPath] and caches them in memory.
class TheoryLibraryIndex {
  final String assetPath;
  final AssetBundle _bundle;
  static List<TheoryResource>? _cache;

  TheoryLibraryIndex({
    this.assetPath = 'assets/theory_index.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  /// Returns all valid theory resources.
  /// Invalid entries (missing fields or empty tags) are skipped.
  Future<List<TheoryResource>> all() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString(assetPath);
    final data = jsonDecode(raw);
    final items = <TheoryResource>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map) {
          final id = e['id'] as String?;
          final title = e['title'] as String?;
          final uri = e['uri'] as String?;
          final tags = (e['tags'] as List?)?.cast<String>();
          if (id != null &&
              title != null &&
              uri != null &&
              tags != null &&
              tags.isNotEmpty) {
            items.add(
              TheoryResource(id: id, title: title, uri: uri, tags: tags),
            );
          }
        }
      }
    }
    _cache = items;
    return items;
  }

  Future<void> reload() async {
    _cache = null;
    await all();
  }
}
