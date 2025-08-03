import 'package:flutter/foundation.dart';

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
import 'services/xp_goal_panel_booster_injector.dart';
import 'services/training_session_fingerprint_service.dart';
import 'helpers/training_pack_storage.dart';
import 'core/error_logger.dart';
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
    await _loadAssets();
    await _initServices();
    await _setupCloudSync(cloud);
    await SessionNoteService(cloud: cloud).load();
    final packs = await TrainingPackStorage.load();
    if (packs.isEmpty) {
      await TrainingPackService.generateDefaultPersonalPack(cloud: cloud);
    }
    registry.registerIfAbsent<EvaluationExecutor>(EvaluationExecutorService());
    registry.registerIfAbsent<TrainingSessionFingerprintService>(
        TrainingSessionFingerprintService());
    XpGoalPanelBoosterInjector.instance.inject();
    _registry = registry;
    return registry;
  }

  static void dispose() {
    _sync?.dispose();
    _sync = null;
    _registry = null;
  }

  static Future<void> _loadAssets() async {
    try {
      await _run('TrainingPackAssetLoader.loadAll', () => TrainingPackAssetLoader.instance.loadAll());
      await _run('PackLibraryLoaderService.loadLibrary', () => PackLibraryLoaderService.instance.loadLibrary());
      await _run('TrainingPackLibraryV2.loadFromFolder', () => TrainingPackLibraryV2.instance.loadFromFolder());
    } catch (e, s) {
      ErrorLogger.instance.logError('Failed to load assets', e, s);
      rethrow;
    }
  }

  static Future<void> _initServices() async {
    try {
      await _run('PackFavoriteService.load', () => PackFavoriteService.instance.load());
      await _run('PackRatingService.load', () => PackRatingService.instance.load());
      await _run('TrainingPackCommentsService.load', () => TrainingPackCommentsService.instance.load());
      await _run('FavoritePackService.init', () => FavoritePackService.instance.init());
      await _run('PinnedPackService.init', () => PinnedPackService.instance.init());
      await _run('UserProfilePreferenceService.load', () => UserProfilePreferenceService.instance.load());
    } catch (e, s) {
      ErrorLogger.instance.logError('Failed to initialize services', e, s);
      rethrow;
    }
  }

  static Future<void> _setupCloudSync(CloudSyncService? cloud) async {
    if (cloud == null) return;
    try {
      await _run('CloudSyncService.init', cloud.init);
      await _run('CloudSyncService.syncUp', cloud.syncUp);
      await _run('CloudSyncService.syncDown', cloud.syncDown);
      await _run('CloudSyncService.loadHands', cloud.loadHands);
      cloud.watchChanges();
      _sync = ConnectivitySyncController(cloud: cloud);
    } catch (e, s) {
      ErrorLogger.instance.logError('Failed to setup cloud sync', e, s);
    }
  }

  static Future<void> _run(String name, Future<void> Function() task) async {
    try {
      debugPrint('Starting $name');
      await task();
      debugPrint('Completed $name');
    } catch (e, s) {
      ErrorLogger.instance.logError('$name failed', e, s);
      rethrow;
    }
  }
}
