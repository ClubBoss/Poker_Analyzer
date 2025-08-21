import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:indexed_db';
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:poker_analyzer/core/error_logger.dart';
import '../services/service_registry.dart';
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

class PluginLoader {
  static const String _suffix = 'Plugin.dart';
  const PluginLoader();

  Database? _db;
  Map<String, bool>? _config;
  Map<String, dynamic>? _cache;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    _db = await window.indexedDB!.open(
      'plugins',
      version: 1,
      onUpgradeNeeded: (e) {
        final db = (e.target as OpenDbRequest).result as Database;
        if (!db.objectStoreNames!.contains('files'))
          db.createObjectStore('files');
        if (!db.objectStoreNames!.contains('config'))
          db.createObjectStore('config');
        if (!db.objectStoreNames!.contains('cache'))
          db.createObjectStore('cache');
      },
    );
    return _db!;
  }

  Future<Map<String, dynamic>?> _loadCache() async {
    if (_cache != null) return _cache;
    final db = await _openDb();
    final txn = db.transaction('cache', 'readonly');
    final store = txn.objectStore('cache');
    final data = await store.getObject('cache');
    await txn.completed;
    if (data is String) {
      try {
        _cache = jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {}
    }
    return _cache;
  }

  Future<void> _writeCache(Map<String, dynamic> cache) async {
    final db = await _openDb();
    final txn = db.transaction('cache', 'readwrite');
    await txn.objectStore('cache').put(jsonEncode(cache), 'cache');
    await txn.completed;
    _cache = cache;
  }

  Future<void> _saveCache(
    List<String> files,
    Map<String, bool> config,
    List<String> plugins,
    Map<String, String> checksums,
  ) async {
    await _writeCache(<String, dynamic>{
      'files': files,
      'config': config,
      'plugins': plugins,
      'checksums': checksums,
    });
  }

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
    final db = await _openDb();
    final txn = db.transaction('config', 'readonly');
    final data = await txn.objectStore('config').getObject('config');
    await txn.completed;
    if (data is String) {
      try {
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

  Future<String?> _readFile(String name) async {
    final db = await _openDb();
    final txn = db.transaction('files', 'readonly');
    final data = await txn.objectStore('files').getObject(name);
    await txn.completed;
    return data as String?;
  }

  Future<List<String>> _listFiles() async {
    final db = await _openDb();
    final txn = db.transaction('files', 'readonly');
    final keys = await txn.objectStore('files').getAllKeys();
    await txn.completed;
    return keys.cast<String>();
  }

  Future<Plugin?> loadFromFile(String name, PluginManager manager) async {
    final config = await loadConfig();
    if (config[name] == false) {
      ErrorLogger.instance.logError('Plugin skipped: $name');
      await manager.logStatus(name, 'skipped');
      return null;
    }
    final code = await _readFile(name);
    if (code == null) return null;
    final blob = Blob([code], 'text/plain');
    final url = Url.createObjectUrlFromBlob(blob);
    final port = ReceivePort();
    Isolate? isolate;
    try {
      isolate = await Isolate.spawnUri(
        Uri.parse(url),
        <String>[],
        port.sendPort,
      );
      final msg = await port.first.timeout(const Duration(seconds: 2));
      Plugin? plugin;
      if (msg is Plugin) {
        plugin = msg;
      } else if (msg is Map && msg['plugin'] is String) {
        plugin = _createByName(msg['plugin'] as String);
      }
      if (plugin != null) {
        ErrorLogger.instance.logError('Plugin loaded: $name');
        await manager.logStatus(name, 'loaded');
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
      Url.revokeObjectUrl(url);
    }
    return null;
  }

  Future<bool> downloadFromUrl(String url, {String? checksum}) async {
    final uri = Uri.parse(url);
    final name = uri.pathSegments.last;
    if (!name.endsWith(_suffix)) {
      throw Exception('Invalid plugin file');
    }
    final cached = await _loadCache();
    final cachedDigest = (cached?['checksums'] as Map?)
        ?.cast<String, String>()[name];
    final existing = await _readFile(name);
    if (checksum != null &&
        cachedDigest != null &&
        cachedDigest == checksum.toLowerCase() &&
        existing != null) {
      final ctx = navigatorKey.currentState?.context;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Plugin up to date')));
      }
      return false;
    }
    final request = await HttpRequest.request(url, responseType: 'arraybuffer');
    if (request.status != 200) {
      throw Exception('HTTP ${request.status}');
    }
    final bytes = Uint8List.view(request.response as ByteBuffer);
    final code = utf8.decode(bytes);
    final digest = sha256.convert(bytes).toString();
    if (checksum != null && checksum.toLowerCase() != digest) {
      throw Exception('Checksum mismatch');
    }
    final db = await _openDb();
    final txn = db.transaction('files', 'readwrite');
    await txn.objectStore('files').put(code, name);
    await txn.completed;
    final cacheMap = cached ?? <String, dynamic>{};
    final checksums =
        (cacheMap['checksums'] as Map?)?.cast<String, String>() ??
        <String, String>{};
    checksums[name] = digest;
    cacheMap['checksums'] = checksums;
    await _writeCache(cacheMap);
    return true;
  }

  Future<void> delete(String name) async {
    final db = await _openDb();
    var txn = db.transaction('files', 'readwrite');
    await txn.objectStore('files').delete(name);
    await txn.completed;

    final config = await loadConfig();
    config.remove(name);
    txn = db.transaction('config', 'readwrite');
    await txn.objectStore('config').put(jsonEncode(config), 'config');
    await txn.completed;
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
    await _writeCache(cache);
  }

  Future<void> loadAll(
    ServiceRegistry registry,
    PluginManager manager, {
    void Function(double progress)? onProgress,
    BuildContext? context,
  }) async {
    final builtIn = loadBuiltInPlugins();
    final files = await _listFiles();
    final config = await loadConfig();
    final cached = await _loadCache();
    final cachedFiles =
        (cached?['files'] as List?)?.cast<String>() ?? <String>[];
    final cachedConfig =
        (cached?['config'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    final match =
        const DeepCollectionEquality().equals(cachedFiles, files) &&
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
        final code = await _readFile(file) ?? '';
        checksums[file] = sha256.convert(utf8.encode(code)).toString();
      }
      await _saveCache(files, config, pluginNames, checksums);
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
