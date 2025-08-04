import '../models/v2/training_pack_template.dart';
import 'training_pack_asset_loader.dart';

/// Loads training pack templates from the local pack library.
class PackLibraryTemplateLoader {
  const PackLibraryTemplateLoader._();

  /// Loads the template with [id] from the library.
  static Future<TrainingPackTemplate?> load(String id) async {
    await TrainingPackAssetLoader.instance.loadAll();
    return TrainingPackAssetLoader.instance.getById(id);
  }
}
