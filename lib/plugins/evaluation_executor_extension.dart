import 'package:poker_analyzer/services/evaluation_executor_service.dart';
import 'package:poker_analyzer/services/service_registry.dart';

import 'service_extension.dart';

class EvaluationExecutorExtension extends ServiceExtension<EvaluationExecutor> {
  const EvaluationExecutorExtension();

  @override
  EvaluationExecutor create(ServiceRegistry registry) =>
      EvaluationExecutorService();
}
