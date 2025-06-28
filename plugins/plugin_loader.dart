import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poker_ai_analyzer/services/service_registry.dart';

import 'converter_discovery_plugin.dart';
import 'converter_plugin.dart';
import 'plugin.dart';
import 'plugin_manager.dart';
import 'sample_logging_plugin.dart';
import 'converters/poker_analyzer_json_converter.dart';
import 'converters/simple_hand_history_converter.dart';
import 'converters/pokerstars_hand_history_converter.dart';

/// Prototype loader for built-in plug-ins.
///
/// Future iterations may support loading plugins dynamically. For now this
/// returns the set of plug-ins bundled directly with the application.
class PluginLoader {
  /// Returns all built-in plug-ins included with the application.
  List<Plugin> loadBuiltInPlugins() {
    final converters = <ConverterPlugin>[
      PokerAnalyzerJsonConverter(),
      SimpleHandHistoryConverter(),
      PokerStarsHandHistoryConverter(),
    ];
    return <Plugin>[
      SampleLoggingPlugin(),
      ConverterDiscoveryPlugin(converters),
    ];
  }

  Future<void> loadAll(ServiceRegistry registry, PluginManager manager) async {
    for (final plugin in loadBuiltInPlugins()) {
      manager.load(plugin);
    }
    final dir = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'plugins'));
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          final name = p.basename(entity.path);
          if (name.endsWith('.dart') && name.contains('Plugin')) {
            final port = ReceivePort();
            try {
              await Isolate.spawnUri(entity.uri, <String>[], port.sendPort);
              await port.first;
              print('Plugin loaded: $name');
            } catch (_) {
              print('Plugin failed: $name');
            } finally {
              port.close();
            }
          }
        }
      }
    }
    manager.initializeAll(registry);
  }
}
