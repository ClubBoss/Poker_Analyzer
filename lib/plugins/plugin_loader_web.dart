import 'package:flutter/material.dart';
import '../services/service_registry.dart';
import 'plugin.dart';
import 'plugin_manager.dart';

class PluginLoader {
  const PluginLoader();

  List<Plugin> loadBuiltInPlugins() => const [];

  Future<Map<String, bool>> loadConfig() async => <String, bool>{};

  Future<Plugin?> loadFromFile(dynamic file, PluginManager manager) async => null;

  Future<void> downloadFromUrl(String url, {String? checksum}) async {}

  Future<void> loadAll(
    ServiceRegistry registry,
    PluginManager manager, {
    void Function(double progress)? onProgress,
    BuildContext? context,
  }) async {}
}
