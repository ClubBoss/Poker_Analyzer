import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import '../services/ab_test_engine.dart';
import '../services/theme_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/app_info_service.dart';
import '../widgets/player_zone_widget.dart';
import 'provider_globals.dart';
import '../utils/loadable_extension.dart';

/// Core application providers such as authentication and configuration.
List<SingleChildWidget> buildCoreProviders(CloudSyncService cloud) {
  return [
    ChangeNotifierProvider<AuthService>.value(value: auth),
    ChangeNotifierProvider<RemoteConfigService>.value(value: rc),
    ChangeNotifierProvider<AbTestEngine>.value(value: ab),
    ChangeNotifierProvider(create: (_) => ThemeService()..init()),
    Provider<CloudSyncService>.value(value: cloud),
    Provider(create: (_) => PlayerZoneRegistry()),
    Provider(create: (_) => AppInfoService()),
  ];
}
