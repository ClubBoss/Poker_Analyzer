import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_bootstrap.dart';
import 'app_providers.dart';
import 'core/error_logger.dart';
import 'plugins/plugin_loader.dart';
import 'plugins/plugin_manager.dart';
import 'services/ab_test_engine.dart';
import 'services/asset_sync_service.dart';
import 'services/auth_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/evaluation_settings_service.dart';
import 'services/goal_progress_cloud_service.dart';
import 'services/mistake_hint_service.dart';
import 'services/mistake_pack_cloud_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'services/service_registry.dart';
import 'services/training_pack_cloud_sync_service.dart';
import 'services/training_pack_storage_service.dart';
import 'services/training_pack_template_storage_service.dart';
import 'main.dart';

class AppInitializer {
  const AppInitializer._();

  static Future<Widget> init() async {
    auth = AuthService();
    rc = RemoteConfigService();
    if (!CloudSyncService.isLocal) {
      await Firebase.initializeApp();
      await NotificationService.init();
      await rc.load();
      if (!auth.isSignedIn) {
        final uid = await auth.signInAnonymously();
        if (uid != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('anon_uid_log', uid);
        }
      }
    }
    ab = AbTestEngine(remote: rc);
    await ab.init();
    final cloud = CloudSyncService();
    final registry = ServiceRegistry();
    await AppBootstrap.init(cloud: cloud, registry: registry);
    final pluginManager = PluginManager();
    final loader = PluginLoader();
    final dir = Directory('plugins');
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final plugin = await loader.loadFromFile(entity, pluginManager);
          if (plugin != null) {
            pluginManager.load(plugin);
          }
        }
      }
    }
    for (final p in loader.loadBuiltInPlugins()) {
      pluginManager.load(p);
    }
    pluginManager.initializeAll(registry);
    packStorage = TrainingPackStorageService(cloud: cloud);
    await packStorage.load();
    await packStorage.loadBuiltInPacks();
    packCloud = TrainingPackCloudSyncService();
    await packCloud.init();
    mistakeCloud = MistakePackCloudService();
    goalCloud = GoalProgressCloudService();
    templateStorage = TrainingPackTemplateStorageService(
      cloud: packCloud,
      goals: goalCloud,
    );
    await templateStorage.load();
    await packCloud.syncDown(packStorage);
    await packCloud.syncDownTemplates(templateStorage);
    await packCloud.syncDownStats();
    await packCloud.syncUpTemplates(templateStorage);
    unawaited(
      AssetSyncService.instance.syncIfNeeded().catchError(
            (e, st) =>
                ErrorLogger.instance.logError('Asset sync failed', e, st),
          ),
    );
    await EvaluationSettingsService.instance.load();
    await MistakeHintService.instance.load();
    return MultiProvider(
      providers: buildAppProviders(cloud),
      child: const PokerAIAnalyzerApp(),
    );
  }
}
