import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poker_ai_analyzer/core/error_logger.dart';
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
  static const String _suffix = 'Plugin.dart';
  Map<String, bool>? _config;

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

  Plugin? _createByName(String name) {
    switch (name) {
      case 'SampleLoggingPlugin':
        return SampleLoggingPlugin();
      case 'ConverterDiscoveryPlugin':
        return ConverterDiscoveryPlugin(<ConverterPlugin>[
          PokerAnalyzerJsonConverter(),
          SimpleHandHistoryConverter(),
          PokerStarsHandHistoryConverter(),
        ]);
    }
    return null;
  }

  Future<Map<String, bool>> loadConfig() async {
    if (_config != null) return _config!;
    final dir = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'plugins'));
    final file = File(p.join(dir.path, 'plugin_config.json'));
    if (await file.exists()) {
      try {
        final data = await file.readAsString();
        final map = jsonDecode(data) as Map<String, dynamic>;
        _config = map.map((k, v) => MapEntry(k, v == true));
      } catch (_) {
        _config = <String, bool>{};
      }
    } else {
      _config = <String, bool>{};
    }
    return _config!;
  }

  Future<Plugin?> loadFromFile(File file) async {
    final name = p.basename(file.path);
    final config = await loadConfig();
    if (config[name] == false) {
      ErrorLogger.instance.logError('Plugin skipped: $name');
      return null;
    }
    final port = ReceivePort();
    Isolate? isolate;
    try {
      isolate = await Isolate.spawnUri(file.uri, <String>[], port.sendPort);
      final msg = await port.first.timeout(const Duration(seconds: 2));
      Plugin? plugin;
      if (msg is Plugin) {
        plugin = msg;
      } else if (msg is Map && msg['plugin'] is String) {
        plugin = _createByName(msg['plugin'] as String);
      }
      if (plugin != null) {
        ErrorLogger.instance.logError('Plugin loaded: $name');
        return plugin;
      }
      ErrorLogger.instance.logError('Plugin failed: $name');
    } on TimeoutException {
      ErrorLogger.instance.logError('Plugin timeout: $name');
    } catch (e, st) {
      ErrorLogger.instance.logError('Plugin failed: $name', e, st);
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      port.close();
    }
    return null;
  }

  Future<void> loadAll(
    ServiceRegistry registry,
    PluginManager manager, {
    void Function(double progress)? onProgress,
  }) async {
    final builtIn = loadBuiltInPlugins();
    final dir = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'plugins'));
    final files = <File>[];
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith(_suffix)) {
          files.add(entity);
        }
      }
    }
    final total = builtIn.length + files.length;
    var done = 0;
    for (final plugin in builtIn) {
      manager.load(plugin);
      done++;
      onProgress?.call(done / total);
    }
    for (final file in files) {
      final plugin = await loadFromFile(file);
      if (plugin != null) {
        manager.load(plugin);
      }
      done++;
      onProgress?.call(done / total);
    }
    manager.initializeAll(registry);
  }
}
