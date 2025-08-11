import '../asset_manifest.dart';
import 'pack_library_index_loader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';

class AdvancedLearningPathSeeder {
  const AdvancedLearningPathSeeder();

  Future<void> generateAdvancedPath() async {
    await PackLibraryIndexLoader.instance.load();
    final manifest = await AssetManifest.instance;
    final library = PackLibraryIndexLoader.instance.library;

    final selected = _selectPacks(library);
    final paths = <String>[];
    for (final p in selected) {
      final path = _findAssetPath(manifest, p.id);
      if (path != null) paths.add(path);
    }

    final unique = <String>[];
    final seen = <String>{};
    for (final p in paths) {
      if (seen.add(p)) unique.add(p);
    }

    const writer = YamlWriter();
    await writer.write({
      'packs': unique,
    }, 'assets/learning_paths/advanced_path.yaml');
  }

  List<TrainingPackTemplateV2> _selectPacks(
    List<TrainingPackTemplateV2> packs,
  ) {
    final list = <TrainingPackTemplateV2>[];
    for (final p in packs) {
      final aud = p.audience?.toLowerCase();
      final tags = p.tags.map((t) => t.toLowerCase()).toList();
      if (p.spotCount < 2) continue;
      if (aud == 'advanced') {
        list.add(p);
      } else if (tags.contains('advanced') ||
          tags.contains('postflop-jam') ||
          tags.contains('bluffcatch') ||
          tags.contains('icm') ||
          tags.contains('finaltable') ||
          tags.contains('hero-call')) {
        list.add(p);
      }
    }
    list.sort((a, b) {
      final cmp = _rank(a).compareTo(_rank(b));
      if (cmp != 0) return cmp;
      return a.spotCount.compareTo(b.spotCount);
    });
    return list;
  }

  int _rank(TrainingPackTemplateV2 p) {
    final name = p.name.toLowerCase();
    final tags = p.tags.map((t) => t.toLowerCase()).toList();
    if (name.contains('postflop') && name.contains('jam') ||
        tags.contains('postflop-jam')) {
      return 0;
    }
    if (name.contains('bluffcatch') || tags.contains('bluffcatch')) return 1;
    if (name.contains('hero call') ||
        name.contains('hero-call') ||
        tags.contains('hero-call')) {
      return 2;
    }
    if (tags.contains('icm') || tags.contains('finaltable')) return 3;
    if (name.contains('delayed') || tags.contains('delayed')) return 4;
    if (name.contains('river') || tags.contains('river')) return 5;
    return 6;
  }

  String? _findAssetPath(Map<String, dynamic> manifest, String id) {
    for (final entry in manifest.keys) {
      if (entry.startsWith('assets/packs/') && entry.endsWith('$id.yaml')) {
        return entry;
      }
    }
    return null;
  }
}
