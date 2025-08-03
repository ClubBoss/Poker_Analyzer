import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import '../services/ab_test_engine.dart';
import '../services/training_pack_storage_service.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../services/mistake_pack_cloud_service.dart';
import '../services/goal_progress_cloud_service.dart';
import '../services/goal_sync_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/tag_cache_service.dart';

/// Global instances used across provider groups.
late final AuthService auth;
late final RemoteConfigService rc;
late final AbTestEngine ab;
late final TrainingPackStorageService packStorage;
late final TrainingPackCloudSyncService packCloud;
late final MistakePackCloudService mistakeCloud;
late final GoalProgressCloudService goalCloud;
late final GoalSyncService goalSync;
late final TrainingPackTemplateStorageService templateStorage;
late final TagCacheService tagCache;
