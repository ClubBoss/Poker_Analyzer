import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poker_analyzer/core/error_logger.dart';
import 'package:poker_analyzer/services/service_registry.dart';
import '../main.dart';

import 'converter_discovery_plugin.dart';
import 'converter_plugin.dart';
import 'plugin.dart';
import 'plugin_manager.dart';
import 'sample_logging_plugin.dart';
import 'converters/poker_analyzer_json_converter.dart';
import 'converters/simple_hand_history_converter.dart';
import 'converters/pokerstars_hand_history_converter.dart';
import 'converters/ggpoker_hand_history_converter.dart';
import 'converters/winamax_hand_history_converter.dart';
import 'converters/partypoker_hand_history_converter.dart';
import 'converters/wpn_hand_history_converter.dart';
import 'converters/888poker_hand_history_converter.dart';
import 'converters/ipoker_hand_history_converter.dart';
import 'poker_stars_converter_plugin.dart';
import 'gg_poker_converter_plugin.dart';
import 'ipoker_converter_plugin.dart';
import 'partypoker_converter_plugin.dart';
import '../../plugins/LocalEvPlugin.dart';

/// Prototype loader for built-in plug-ins.
///
/// Future iterations may support loading plugins dynamically. For now this
/// returns the set of plug-ins bundled directly with the application.
class PluginLoader {
  static const String _suffix = 'Plugin.dart';
  Map<String, bool>? _config;
  Map<String, dynamic>? _cache;

  Future<bool> _verify(File file) async {
    final sig = File('${file.path}.sha256');
    if (!await sig.exists()) return true;
    final expected = (await sig.readAsString()).trim().toLowerCase();
    final digest = sha256.convert(await file.readAsBytes()).toString();
    return digest == expected;
  }

  Future<File> _cacheFile() async {
    return File(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'plugin_cache.json',
      ),
    );
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
    Map<String, String> checksums,
  ) async {
    final file = await _cacheFile();
    await file.writeAsString(
      jsonEncode(<String, dynamic>{
        'files': files,
        'config': config,
        'plugins': plugins,
        'checksums': checksums,
      }),
    );
  }

  /// Returns all built-in plug-ins included with the application.
  List<Plugin> loadBuiltInPlugins() {
    final converters = <ConverterPlugin>[
      PokerAnalyzerJsonConverter(),
      SimpleHandHistoryConverter(),
      PokerStarsHandHistoryConverter(),
      GGPokerHandHistoryConverter(),
      WinamaxHandHistoryConverter(),
      PartypokerHandHistoryConverter(),
      WpnHandHistoryConverter(),
      Poker888HandHistoryConverter(),
      IpokerHandHistoryConverter(),
    ];
    return <Plugin>[
      SampleLoggingPlugin(),
      ConverterDiscoveryPlugin(converters),
      LocalEvPlugin(),
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
          GGPokerHandHistoryConverter(),
          WinamaxHandHistoryConverter(),
          PartypokerHandHistoryConverter(),
          WpnHandHistoryConverter(),
          Poker888HandHistoryConverter(),
          IpokerHandHistoryConverter(),
        ]);
      case 'PokerStarsConverterPlugin':
        return PokerStarsConverterPlugin();
      case 'GGPokerConverterPlugin':
        return GGPokerConverterPlugin();
      case 'PartyPokerConverterPlugin':
        return PartyPokerConverterPlugin();
      case 'IpokerConverterPlugin':
        return IpokerConverterPlugin();
      case 'LocalEvPlugin':
        return LocalEvPlugin();
    }
    return null;
  }

  Future<Map<String, bool>> loadConfig() async {
    if (_config != null) return _config!;
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'plugins'),
    );
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

  Future<Plugin?> loadFromFile(File file, PluginManager manager) async {
    final name = p.basename(file.path);
    final config = await loadConfig();
    if (config[name] == false) {
      ErrorLogger.instance.logError('Plugin skipped: $name');
      await manager.logStatus(name, 'skipped');
      return null;
    }
    if (!await _verify(file)) {
      ErrorLogger.instance.logError('Checksum mismatch: $name');
      await manager.logStatus(name, 'failed');
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
        await manager.logStatus(name, 'loaded', plugin: plugin);
        return plugin;
      }
      ErrorLogger.instance.logError('Plugin failed: $name');
      await manager.logStatus(name, 'failed');
    } on TimeoutException {
      ErrorLogger.instance.logError('Plugin timeout: $name');
      await manager.logStatus(name, 'failed');
    } catch (e, st) {
      ErrorLogger.instance.logError('Plugin failed: $name', e, st);
      await manager.logStatus(name, 'failed');
    } finally {
      isolate?.kill(priority: Isolate.immediate);
      port.close();
    }
    return null;
  }

  Future<bool> downloadFromUrl(String url, {String? checksum}) async {
    final uri = Uri.parse(url);
    final name = p.basename(uri.path);
    if (!name.endsWith(_suffix)) {
      throw Exception('Invalid plugin file');
    }
    final dir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'plugins'),
    );
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, name));
    final cached = await _loadCache();
    final cachedDigest = (cached?['checksums'] as Map?)
        ?.cast<String, String>()[name];
    if (checksum != null &&
        cachedDigest != null &&
        cachedDigest == checksum.toLowerCase() &&
        await file.exists()) {
      final ctx = navigatorKey.currentState?.context;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Plugin up to date')));
      }
      return false;
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final bytes = await response
          .fold<BytesBuilder>(BytesBuilder(), (b, d) => b..add(d))
          .then((b) => b.takeBytes());
      await file.writeAsBytes(bytes);
      final digest = sha256.convert(bytes).toString();
      if (checksum != null && checksum.toLowerCase() != digest) {
        await file.delete();
        throw Exception('Checksum mismatch');
      }
      final cache = cached ?? <String, dynamic>{};
      final checksums =
          (cache['checksums'] as Map?)?.cast<String, String>() ??
          <String, String>{};
      checksums[name] = digest;
      cache['checksums'] = checksums;
      final f = await _cacheFile();
      await f.writeAsString(jsonEncode(cache));
      _cache = cache;
    } finally {
      client.close(force: true);
    }
    return true;
  }

  Future<void> delete(String name) async {
    final supportDir = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'plugins'),
    );
    final supportFile = File(p.join(supportDir.path, name));
    if (await supportFile.exists()) await supportFile.delete();
    final rootFile = File(p.join('plugins', name));
    if (await rootFile.exists()) await rootFile.delete();

    final config = await loadConfig();
    config.remove(name);
    await supportDir.create(recursive: true);
    final configFile = File(p.join(supportDir.path, 'plugin_config.json'));
    await configFile.writeAsString(jsonEncode(config));
    _config = Map<String, bool>.from(config);

    final cache = await _loadCache() ?? <String, dynamic>{};
    final files =
        (cache['files'] as List?)?.cast<String>().toList() ?? <String>[];
    files.remove(name);
    final checksums =
        (cache['checksums'] as Map?)?.cast<String, String>() ??
        <String, String>{};
    checksums.remove(name);
    cache['files'] = files;
    cache['checksums'] = checksums;
    final f = await _cacheFile();
    await f.writeAsString(jsonEncode(cache));
    _cache = cache;
  }

  Future<void> loadAll(
    ServiceRegistry registry,
    PluginManager manager, {
    void Function(double progress)? onProgress,
    BuildContext? context,
  }) async {
    final builtIn = loadBuiltInPlugins();
    final support = await getApplicationSupportDirectory();
    final supportDir = Directory(p.join(support.path, 'plugins'));
    final files = <File>[];
    if (await supportDir.exists()) {
      await for (final entity in supportDir.list()) {
        if (entity is File && entity.path.endsWith(_suffix)) {
          files.add(entity);
        }
      }
    }
    final rootDir = Directory('plugins');
    if (await rootDir.exists()) {
      await for (final entity in rootDir.list()) {
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
        (cached?['config'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final match =
        const DeepCollectionEquality().equals(cachedFiles, [
          for (final f in files) p.basename(f.path),
        ]) &&
        const DeepCollectionEquality().equals(
          config,
          cachedConfig.map((k, v) => MapEntry(k, v == true)),
        );

    final pluginNames = <String>[];
    final loadedPlugins = <Plugin>[];

    if (match) {
      pluginNames.addAll(
        (cached?['plugins'] as List?)?.cast<String>() ?? <String>[],
      );
      for (final name in pluginNames) {
        final plugin = _createByName(name);
        if (plugin != null) {
          loadedPlugins.add(plugin);
        }
      }
    } else {
      for (final file in files) {
        final plugin = await loadFromFile(file, manager);
        if (plugin != null) {
          pluginNames.add(plugin.runtimeType.toString());
          loadedPlugins.add(plugin);
        }
      }
      final checksums = <String, String>{};
      for (final file in files) {
        final bytes = await file.readAsBytes();
        checksums[p.basename(file.path)] = sha256.convert(bytes).toString();
      }
      await _saveCache(
        [for (final f in files) p.basename(f.path)],
        config,
        pluginNames,
        checksums,
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
        await manager.logStatus(name, 'duplicate');
      }
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate plugins: ${duplicates.join(', ')}'),
          ),
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
