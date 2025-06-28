import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
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
  Map<String, dynamic>? _cache;

  Future<File> _cacheFile() async {
    return File(p.join((await getApplicationSupportDirectory()).path, 'plugin_cache.json'));
  }

  Future<Map<String, dynamic>?> _loadCache() async {
    if (_cache != null) return _cache;
    final file = await _cacheFile();
    if (await file.exists()) {
      try {
        _cache = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      } catch (_) {}
    }
    return _cache;
  }

  Future<void> _saveCache(
    List<String> files,
    Map<String, bool> config,
    List<String> plugins,
  ) async {
    final file = await _cacheFile();
    await file.writeAsString(jsonEncode(<String, dynamic>{
      'files': files,
      'config': config,
      'plugins': plugins,
    }));
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _mapEquals(Map<String, bool> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != (b[key] == true)) return false;
    }
    return true;
  }

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
    BuildContext? context,
  }) async {
    final builtIn = loadBuiltInPlugins();
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'plugins'));
    final files = <File>[];
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith(_suffix)) {
          files.add(entity);
        }
      }
    }
    final config = await loadConfig();
    final cached = await _loadCache();
    final cachedFiles =
        (cached?['files'] as List?)?.cast<String>() ?? <String>[];
    final cachedConfig =
        (cached?['config'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final match = _listEquals(
          cachedFiles,
          [for (final f in files) p.basename(f.path)],
        ) &&
        _mapEquals(config, cachedConfig);

    final pluginNames = <String>[];
    final loadedPlugins = <Plugin>[];

    if (match) {
      pluginNames.addAll((cached?['plugins'] as List?)?.cast<String>() ?? <String>[]);
      for (final name in pluginNames) {
        final plugin = _createByName(name);
        if (plugin != null) {
          loadedPlugins.add(plugin);
        }
      }
    } else {
      for (final file in files) {
        final plugin = await loadFromFile(file);
        if (plugin != null) {
          pluginNames.add(plugin.runtimeType.toString());
          loadedPlugins.add(plugin);
        }
      }
      await _saveCache(
        [for (final f in files) p.basename(f.path)],
        config,
        pluginNames,
      );
    }

    final all = <Plugin>[...builtIn, ...loadedPlugins];
    final seen = <String>{};
    final unique = <Plugin>[];
    final duplicates = <String>[];
    for (final plugin in all) {
      final name = plugin.runtimeType.toString();
      if (seen.add(name)) {
        unique.add(plugin);
      } else {
        duplicates.add(name);
      }
    }
    if (duplicates.isNotEmpty) {
      for (final name in duplicates) {
        ErrorLogger.instance.logError('Duplicate plugin: $name');
      }
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate plugins: ${duplicates.join(', ')}')),
        );
      }
    }

    final total = unique.length;
    var done = 0;
    for (final plugin in unique) {
      manager.load(plugin);
      done++;
      onProgress?.call(done / total);
    }
    manager.initializeAll(registry);
  }
}
