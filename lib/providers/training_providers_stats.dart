import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/cloud_sync_service.dart';
import '../services/cloud_training_history_service.dart';
import '../services/training_spot_storage_service.dart';
import '../services/training_stats_service.dart';
import '../services/saved_hand_storage_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/saved_hand_stats_service.dart';
import '../services/saved_hand_export_service.dart';

/// Providers supporting training stats and saved hand features.
List<SingleChildWidget> buildTrainingStatsProviders() {
  return [
    Provider(create: (_) => CloudTrainingHistoryService()..init()),
    ChangeNotifierProvider(
      create: (context) =>
          TrainingSpotStorageService(cloud: context.read<CloudSyncService>()),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          TrainingStatsService(cloud: context.read<CloudSyncService>())..init(),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          SavedHandStorageService(cloud: context.read<CloudSyncService>())
            ..init(),
    ),
    ChangeNotifierProvider(
      create: (context) => SavedHandManagerService(
        storage: context.read<SavedHandStorageService>(),
        cloud: context.read<CloudSyncService>(),
        stats: context.read<TrainingStatsService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => SavedHandStatsService(
        manager: context.read<SavedHandManagerService>(),
      ),
    ),
    Provider(
      create: (context) => SavedHandExportService(
        manager: context.read<SavedHandManagerService>(),
        stats: context.read<SavedHandStatsService>(),
      ),
    ),
  ];
}
