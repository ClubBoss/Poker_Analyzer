import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Simple representation of a theory snippet injected into learning path stages.
class TheorySnippet {
  final String id;
  final String title;
  final String markdownContent;
  final List<String> mediaRefs;

  const TheorySnippet({
    required this.id,
    required this.title,
    required this.markdownContent,
    this.mediaRefs = const [],
  });
}

class LearningPathTheoryInjectorService {
  final String indexAssetPath;
  final AssetBundle _bundle;
  List<_IndexEntry>? _cache;

  LearningPathTheoryInjectorService({
    this.indexAssetPath = 'assets/theory_index.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  /// Returns sorted list of theory snippets matching any of [tags].
  Future<List<TheorySnippet>> getTheoryForTags(List<String> tags) async {
    if (tags.isEmpty) return [];
    final index = await _loadIndex();
    final lower = tags.map((e) => e.toLowerCase()).toSet();
    final matches = index
        .where((e) => e.tags.any((t) => lower.contains(t.toLowerCase())))
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    final result = <TheorySnippet>[];
    for (final m in matches) {
      final md = await _loadMarkdown(m.uri);
      result.add(TheorySnippet(
        id: m.id,
        title: m.title,
        markdownContent: md,
        mediaRefs: m.media,
      ));
    }
    return result;
  }

  Future<List<_IndexEntry>> _loadIndex() async {
    if (_cache != null) return _cache!;
    final raw = await _bundle.loadString(indexAssetPath);
    final data = jsonDecode(raw);
    final items = <_IndexEntry>[];
    if (data is List) {
      for (final e in data) {
        if (e is Map) {
          final id = e['id'] as String?;
          final title = e['title'] as String?;
          final uri = e['uri'] as String?;
          final tags = (e['tags'] as List?)?.cast<String>() ?? const <String>[];
          final media = (e['media'] as List?)?.cast<String>() ?? const <String>[];
          if (id != null && title != null && uri != null && tags.isNotEmpty) {
            items.add(_IndexEntry(
              id: id,
              title: title,
              uri: uri,
              tags: tags,
              media: media,
            ));
          }
        }
      }
    }
    _cache = items;
    return items;
  }

  Future<String> _loadMarkdown(String uri) async {
    final path = 'assets/$uri.md';
    try {
      return await _bundle.loadString(path);
    } catch (_) {
      return '';
    }
  }
}

class _IndexEntry {
  final String id;
  final String title;
  final String uri;
  final List<String> tags;
  final List<String> media;

  const _IndexEntry({
    required this.id,
    required this.title,
    required this.uri,
    required this.tags,
    required this.media,
  });
}
