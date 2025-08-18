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

  final Map<String, Map<String, dynamic>> _info =
      <String, Map<String, dynamic>>{};

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
        _info
          ..clear()
          ..addAll(
            map.map((k, v) => MapEntry(k, Map<String, dynamic>.from(v))),
          );
      } catch (_) {}
    }
  }

  Future<void> _saveLog() async {
    final file = await _logFile();
    await file.writeAsString(jsonEncode(_info));
  }

  Future<Map<String, Map<String, dynamic>>> loadStatus() async {
    if (_info.isEmpty) await _loadLog();
    return _info;
  }

  Future<void> logStatus(String file, String status, {Plugin? plugin}) async {
    await _loadLog();
    final entry = _info[file] ?? <String, dynamic>{};
    entry['status'] = status;
    if (plugin != null) {
      entry['name'] = plugin.name;
      entry['description'] = plugin.description;
      entry['version'] = plugin.version;
    }
    _info[file] = entry;
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
