import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/autogen_preset.dart';

class AutogenPresetService {
  AutogenPresetService._();
  static final AutogenPresetService instance = AutogenPresetService._();

  final Map<String, AutogenPreset> _presets = {};
  List<AutogenPreset> get presets => _presets.values.toList();
  AutogenPreset? getById(String id) => _presets[id];

  Future<void> load() async {
    _presets.clear();
    await _loadDefaultPresets();
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('autogen.presets') ?? [];
    for (final s in stored) {
      try {
        final p = AutogenPreset.fromJson(jsonDecode(s));
        _presets[p.id] = p;
      } catch (_) {}
    }
  }

  Future<void> _loadDefaultPresets() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = jsonDecode(manifestContent);
      final presetAssets = manifest.keys.where(
        (k) => k.startsWith('assets/autogen_presets/') && k.endsWith('.json'),
      );
      for (final path in presetAssets) {
        final str = await rootBundle.loadString(path);
        final p = AutogenPreset.fromJson(jsonDecode(str));
        _presets[p.id] = p;
      }
    } catch (_) {}
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _presets.values.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('autogen.presets', list);
  }

  Future<void> savePreset(AutogenPreset preset) async {
    _presets[preset.id] = preset;
    await save();
  }

  Future<void> deletePreset(String id) async {
    _presets.remove(id);
    await save();
  }

  String exportPresets() {
    final list = _presets.values.map((p) => p.toJson()).toList();
    return jsonEncode(list);
  }

  Future<void> importPresets(String jsonStr) async {
    final data = jsonDecode(jsonStr);
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            final p = AutogenPreset.fromJson(item);
            _presets[p.id] = p;
          } catch (_) {}
        }
      }
      await save();
    }
  }

  Future<void> persistLastUsed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('autogen.lastPreset', id);
  }

  Future<AutogenPreset?> loadLastUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('autogen.lastPreset');
    if (id == null) return null;
    return _presets[id];
  }
}
