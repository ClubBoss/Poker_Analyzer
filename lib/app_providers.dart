import 'package:provider/single_child_widget.dart';

import 'services/cloud_sync_service.dart';
import 'providers/core_providers.dart';
import 'providers/training_providers.dart';
import 'providers/analytics_providers.dart';

export 'providers/provider_globals.dart';

/// Builds the complete list of application providers.
List<SingleChildWidget> buildAppProviders(CloudSyncService cloud) {
  return [
    ...buildCoreProviders(cloud),
    ...buildTrainingProviders(),
    ...buildAnalyticsProviders(),
  ];
}
