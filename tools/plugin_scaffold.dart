import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:poker_ai_analyzer/services/error_logger_service.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    ErrorLoggerService.instance.logError('Plugin name required');
    exit(1);
  }
  final name = args.first;
  final file = File(p.join('plugins', '$name.dart'));
  if (file.existsSync()) {
    ErrorLoggerService.instance.logError('Plugin already exists: ${file.path}');
    return;
  }
  final content = '''import 'package:poker_ai_analyzer/plugins/plugin.dart';
import 'package:poker_ai_analyzer/plugins/service_extension.dart';
import 'package:poker_ai_analyzer/services/error_logger_service.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';

class _${name}Service {}

class ${name}Extension extends ServiceExtension<_${name}Service> {
  @override
  _${name}Service create(ServiceRegistry registry) => _${name}Service();
}

class $name implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    ErrorLoggerService.instance.logError('Plugin loaded: $name');
  }

  @override
  List<ServiceExtension<dynamic>> get extensions => <ServiceExtension<dynamic>>[
        ${name}Extension(),
      ];
}
''';
  file.writeAsStringSync(content);
  ErrorLoggerService.instance.logError('Created plugin: ${file.path}');
}
