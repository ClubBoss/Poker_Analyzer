import '../asset_manifest.dart';
import 'pack_library_index_loader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';

class StarterLearningPathSeeder {
  const StarterLearningPathSeeder();

  Future<void> generateStarterPath() async {
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
    await writer.write({'packs': unique},
        'assets/learning_paths/beginner_path.yaml');
  }

  List<TrainingPackTemplateV2> _selectPacks(List<TrainingPackTemplateV2> packs) {
    final list = <TrainingPackTemplateV2>[];
    for (final p in packs) {
      final aud = p.audience?.toLowerCase();
      final tags = p.tags.map((t) => t.toLowerCase()).toList();
      if (aud == 'beginner') {
        list.add(p);
      } else if (tags.contains('beginner') || tags.contains('starter')) list.add(p);
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
    if (name.contains('push') || tags.contains('pushfold')) return 0;
    if (name.contains('call') || tags.contains('call')) return 1;
    if (name.contains('trap') || name.contains('slowplay')) return 2;
    if (p.bb <= 10) return 3;
    if (name.contains('steal') || tags.contains('steal')) return 4;
    return 5;
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
