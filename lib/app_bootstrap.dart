import 'services/training_pack_asset_loader.dart';
import 'services/favorite_pack_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/session_note_service.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> init({CloudSyncService? cloud}) async {
    await TrainingPackAssetLoader.instance.loadAll();
    await FavoritePackService.instance.init();
    if (cloud != null) {
      await cloud.init();
      await cloud.syncUp();
      await cloud.syncDown();
      await cloud.loadHands();
      cloud.watchChanges();
    }
    await SessionNoteService(cloud: cloud).load();
  }
}
