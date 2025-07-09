import 'services/training_pack_asset_loader.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> init() async {
    await TrainingPackAssetLoader.instance.loadAll();
  }
}
