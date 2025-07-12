import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:poker_analyzer/services/service_registry.dart';

import 'plugin.dart';
import 'service_extension.dart';

/// Manages plug-ins for the Poker Analyzer application.
class PluginManager {
  /// List of loaded plug-ins.
  final List<Plugin> _plugins = <Plugin>[];

  final Map<String, String> _status = <String, String>{};

  Future<File> _logFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'plugin_log.json'));
  }

  Future<void> _loadLog() async {
    final file = await _logFile();
    if (await file.exists()) {
      try {
        final data = await file.readAsString();
        final map = jsonDecode(data) as Map<String, dynamic>;
        _status
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(k, v.toString())));
      } catch (_) {}
    }
  }

  Future<void> _saveLog() async {
    final file = await _logFile();
    await file.writeAsString(jsonEncode(_status));
  }

  Future<Map<String, String>> loadStatus() async {
    if (_status.isEmpty) await _loadLog();
    return _status;
  }

  Future<void> logStatus(String name, String status) async {
    await _loadLog();
    _status[name] = status;
    await _saveLog();
  }

  /// Loads a new [plugin].
  void load(Plugin plugin) {
    _plugins.add(plugin);
  }

  /// Initializes all loaded plug-ins using the provided [registry].
  void initializeAll(ServiceRegistry registry) {
    for (final Plugin plugin in _plugins) {
      plugin.register(registry);
      for (final ServiceExtension<dynamic> extension in plugin.extensions) {
        extension.register(registry);
      }
    }
  }
}
