import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:poker_analyzer/core/error_logger.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    ErrorLogger.instance.logError('Plugin name required');
    exit(1);
  }
  final name = args.first;
  final file = File(p.join('plugins', '$name.dart'));
  if (file.existsSync()) {
    ErrorLogger.instance.logError('Plugin already exists: ${file.path}');
    return;
  }
  final content =
      '''import 'package:poker_analyzer/plugins/plugin.dart';
import 'package:poker_analyzer/plugins/service_extension.dart';
import 'package:poker_analyzer/core/error_logger.dart';
import 'package:poker_analyzer/services/service_registry.dart';

class _${name}Service {}

class ${name}Extension extends ServiceExtension<_${name}Service> {
  @override
  _${name}Service create(ServiceRegistry registry) => _${name}Service();
}

class $name implements Plugin {
  @override
  void register(ServiceRegistry registry) {
    ErrorLogger.instance.logError('Plugin loaded: $name');
  }

  @override
  List<ServiceExtension<dynamic>> get extensions => <ServiceExtension<dynamic>>[
        ${name}Extension(),
      ];

  @override
  String get name => '$name';

  @override
  String get description => '';

  @override
  String get version => '1.0.0';
}
''';
  file.writeAsStringSync(content);
  ErrorLogger.instance.logError('Created plugin: ${file.path}');
}
