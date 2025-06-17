// Sample plugin demonstrating service registration.

import 'package:poker_ai_analyzer/services/service_registry.dart';

import 'plugin.dart';

/// Simple logger service for demonstration purposes.
class LoggerService {
  /// Logs a message to the console.
  void log(String message) {
    // In a real application this might write to a file or logging backend.
    print('LOG: \$message');
  }
}

/// Example plug-in that registers a [LoggerService].
class SampleLoggingPlugin implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    registry.register<LoggerService>(LoggerService());
  }
}

