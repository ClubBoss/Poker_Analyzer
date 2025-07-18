import 'services/training_pack_asset_loader.dart';
import 'services/favorite_pack_service.dart';
import 'services/pack_favorite_service.dart';
import 'services/pack_rating_service.dart';
import 'services/training_pack_comments_service.dart';
import 'services/pinned_pack_service.dart';
import 'services/user_profile_preference_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/session_note_service.dart';
import 'services/connectivity_sync_controller.dart';
import 'services/evaluation_executor_service.dart';
import 'services/training_pack_service.dart';
import 'services/service_registry.dart';
import 'services/pack_library_loader_service.dart';
import 'helpers/training_pack_storage.dart';
import 'core/plugin_runtime.dart';
import 'core/training/library/training_pack_library_v2.dart';

class AppBootstrap {
  const AppBootstrap._();

  static ConnectivitySyncController? _sync;
  static ConnectivitySyncController? get sync => _sync;

  static ServiceRegistry? _registry;
  static ServiceRegistry get registry => _registry!;

  static Future<ServiceRegistry> init({
    CloudSyncService? cloud,
    required PluginRuntime runtime,
  }) async {
    await runtime.initialize();
    final ServiceRegistry registry = runtime.registry.createChild();
    await TrainingPackAssetLoader.instance.loadAll();
    await PackLibraryLoaderService.instance.loadLibrary();
    await TrainingPackLibraryV2.instance.loadFromFolder();
    await PackFavoriteService.instance.load();
    await PackRatingService.instance.load();
    await TrainingPackCommentsService.instance.load();
    await FavoritePackService.instance.init();
    await PinnedPackService.instance.init();
    await UserProfilePreferenceService.instance.load();
    if (cloud != null) {
      await cloud.init();
      await cloud.syncUp();
      await cloud.syncDown();
      await cloud.loadHands();
      cloud.watchChanges();
      _sync = ConnectivitySyncController(cloud: cloud);
    }
    await SessionNoteService(cloud: cloud).load();
    final packs = await TrainingPackStorage.load();
    if (packs.isEmpty) {
      await TrainingPackService.generateDefaultPersonalPack(cloud: cloud);
    }
    registry.registerIfAbsent<EvaluationExecutor>(EvaluationExecutorService());
    _registry = registry;
    return registry;
  }

  static void dispose() {
    _sync?.dispose();
    _sync = null;
    _registry = null;
  }
}
