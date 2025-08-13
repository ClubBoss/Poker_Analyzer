import '../asset_manifest.dart';
import 'pack_library_index_loader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';

class IcmPostflopPathSeeder {
  const IcmPostflopPathSeeder();

  Future<void> generateIcmPostflopPath() async {
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
    await writer.write(
        {'packs': unique}, 'assets/learning_paths/icm_postflop_path.yaml');
  }

  List<TrainingPackTemplateV2> _selectPacks(
      List<TrainingPackTemplateV2> packs) {
    final list = <TrainingPackTemplateV2>[];
    for (final p in packs) {
      final tags = p.tags.map((t) => t.toLowerCase()).toList();
      if (p.spotCount < 2) continue;
      if (tags.contains('icm') ||
          tags.contains('finaltable') ||
          tags.contains('bubble') ||
          tags.contains('icm-postflop')) {
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
    if ((name.contains('hero call') ||
            name.contains('hero-call') ||
            tags.contains('hero-call')) &&
        (tags.contains('icm') || tags.contains('icm-postflop'))) {
      return 0;
    }
    if (name.contains('overbet') ||
        tags.contains('overbet') ||
        (name.contains('marginal') && name.contains('call')) ||
        tags.contains('marginal-call')) {
      return 1;
    }
    if (name.contains('float') ||
        tags.contains('float') ||
        name.contains('bluffcatch') ||
        tags.contains('bluffcatch')) {
      return 2;
    }
    return 3;
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
