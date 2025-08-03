import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/evaluation_executor_service.dart';
import '../services/session_analysis_service.dart';
import '../services/user_action_logger.dart';
import '../utils/loadable_extension.dart';

/// Analytics and user action logging providers.
List<SingleChildWidget> buildAnalyticsProviders() {
  return [
    Provider(create: (_) => EvaluationExecutorService()),
    Provider(
      create: (context) =>
          SessionAnalysisService(context.read<EvaluationExecutorService>()),
    ),
    ChangeNotifierProvider(create: (_) => UserActionLogger()..init()),
  ];
}
