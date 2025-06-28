// Sample plugin demonstrating service registration.

import 'package:poker_ai_analyzer/core/error_logger.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';

import 'plugin.dart';
import 'service_extension.dart';

/// Simple logger service for demonstration purposes.
class LoggerService {
  /// Logs a message to the console.
  void log(String message) {
    ErrorLogger.instance.logError('LOG: $message');
  }
}

/// Example plug-in that registers a [LoggerService].
class LoggerServiceExtension extends ServiceExtension<LoggerService> {
  @override
  LoggerService create(ServiceRegistry registry) => LoggerService();
}

class SampleLoggingPlugin implements Plugin {
  @override
  void register(ServiceRegistry registry) {}

  @override
  List<ServiceExtension<dynamic>> get extensions =>
      <ServiceExtension<dynamic>>[LoggerServiceExtension()];
}

