import 'services/training_pack_asset_loader.dart';
import 'services/favorite_pack_service.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> init() async {
    await TrainingPackAssetLoader.instance.loadAll();
    await FavoritePackService.instance.init();
  }
}
