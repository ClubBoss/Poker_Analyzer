import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// A unified configuration source for both Flutter and headless environments.
///
/// Values are resolved with the following precedence:
/// CLI arguments > environment variables > config file > SharedPreferences > defaults.
class ConfigSource {
  ConfigSource._(this._cli, this._env, this._file, this._prefs);

  final Map<String, dynamic> _cli;
  final Map<String, String> _env;
  final Map<String, dynamic> _file;
  final Map<String, dynamic> _prefs;

  /// Creates a [ConfigSource] from the provided sources. [configFile] may be a
  /// JSON or YAML file with flat key/value pairs.
  static Future<ConfigSource> from({
    Map<String, dynamic>? cli,
    Map<String, String>? env,
    String? configFile,
    Map<String, dynamic>? prefs,
  }) async {
    Map<String, dynamic> fileMap = {};
    if (configFile != null) {
      final f = File(configFile);
      if (await f.exists()) {
        final text = await f.readAsString();
        if (configFile.endsWith('.json')) {
          fileMap = jsonDecode(text) as Map<String, dynamic>;
        } else {
          fileMap =
              jsonDecode(jsonEncode(loadYaml(text))) as Map<String, dynamic>;
        }
      }
    }
    return ConfigSource._(
      cli ?? <String, dynamic>{},
      env ?? Platform.environment,
      fileMap,
      prefs ?? <String, dynamic>{},
    );
  }

  /// Returns an empty [ConfigSource] with no values.
  factory ConfigSource.empty() => ConfigSource._({}, {}, {}, {});

  dynamic _resolve(String key) {
    if (_cli.containsKey(key)) return _cli[key];
    final envKey = key.toUpperCase().replaceAll('.', '_');
    if (_env.containsKey(envKey)) return _env[envKey];
    if (_file.containsKey(key)) return _file[key];
    if (_prefs.containsKey(key)) return _prefs[key];
    return null;
  }

  bool? getBool(String key, {bool? defaultValue}) {
    final v = _resolve(key);
    if (v is bool) return v;
    if (v is String) {
      final lower = v.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    if (v is num) return v != 0;
    return defaultValue;
  }

  int? getInt(String key, {int? defaultValue}) {
    final v = _resolve(key);
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  String? getString(String key, {String? defaultValue}) {
    final v = _resolve(key);
    if (v == null) return defaultValue;
    if (v is String) return v;
    return v.toString();
  }

  List<String>? getStringList(String key, {List<String>? defaultValue}) {
    final v = _resolve(key);
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) {
      return v
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return defaultValue;
  }
}
