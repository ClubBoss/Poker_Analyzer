import 'dart:convert';
import 'dart:io';

class ContentManifest {
  static const path = 'content/_manifest.json';

  final Set<String> modules;

  ContentManifest(this.modules);

  static ContentManifest loadSync({String path = path}) {
    try {
      final contents = File(path).readAsStringSync();
      final json = jsonDecode(contents);
      if (json is Map) {
        return ContentManifest(json.keys.map((e) => e.toString()).toSet());
      }
    } catch (_) {}
    return ContentManifest(<String>{});
  }

  bool isReady(String moduleId) => modules.contains(moduleId);
}

bool isReady(String moduleId, {String path = ContentManifest.path}) =>
    ContentManifest.loadSync(path: path).isReady(moduleId);
