import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reward_card_renderer_service.dart';
import 'reward_card_style_tuner_service.dart';
import 'skill_tree_library_service.dart';

/// Builds a reward card preview for a track before it is completed.
class TrackRewardPreviewService {
  final RewardCardRendererService _renderer;
  final _PreviewPreferences _prefs;

  TrackRewardPreviewService._(this._renderer, this._prefs);

  /// Creates a new instance using [library] and [prefs] or defaults.
  static Future<TrackRewardPreviewService> create({
    SkillTreeLibraryService? library,
    SharedPreferences? prefs,
    RewardCardStyleTunerService? styleTuner,
  }) async {
    final basePrefs = prefs ?? await SharedPreferences.getInstance();
    final previewPrefs = _PreviewPreferences(basePrefs);
    final renderer = await RewardCardRendererService.create(
      library: library,
      prefs: previewPrefs,
      styleTuner: styleTuner,
    );
    return TrackRewardPreviewService._(renderer, previewPrefs);
  }

  /// Builds a preview reward card for [trackId] without completion badge.
  Widget buildPreviewCard(String trackId) {
    _prefs.trackId = trackId;
    return _renderer.buildCard(trackId);
  }
}

/// Wrapper around [SharedPreferences] that hides reward completion flags.
class _PreviewPreferences implements SharedPreferences {
  final SharedPreferences _base;
  String trackId = '';

  _PreviewPreferences(this._base);

  @override
  bool? getBool(String key) {
    if (key == 'reward_granted_$trackId') return false;
    return _base.getBool(key);
  }

  @override
  Set<String> getKeys() => _base.getKeys();

  @override
  Object? get(String key) => _base.get(key);

  @override
  bool containsKey(String key) => _base.containsKey(key);

  @override
  double? getDouble(String key) => _base.getDouble(key);

  @override
  int? getInt(String key) => _base.getInt(key);

  @override
  String? getString(String key) => _base.getString(key);

  @override
  List<String>? getStringList(String key) => _base.getStringList(key);

  @override
  Future<bool> setBool(String key, bool value) => _base.setBool(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      _base.setDouble(key, value);

  @override
  Future<bool> setInt(String key, int value) => _base.setInt(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      _base.setString(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      _base.setStringList(key, value);

  @override
  Future<bool> remove(String key) => _base.remove(key);

  @override
  Future<bool> clear() => _base.clear();

  @override
  Future<void> reload() => _base.reload();
}
