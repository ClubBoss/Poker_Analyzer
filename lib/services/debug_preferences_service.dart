import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/debug_panel_preferences.dart';

class DebugPreferencesService extends ChangeNotifier {
  static const _queueResumedKey = 'evaluation_queue_resumed';

  final DebugPanelPreferences _prefs = DebugPanelPreferences();

  bool _snapshotRetentionEnabled = true;
  int _processingDelay = 500;
  bool _queueResumed = false;

  bool get snapshotRetentionEnabled => _snapshotRetentionEnabled;
  int get processingDelay => _processingDelay;
  bool get queueResumed => _queueResumed;

  Future<void> loadSnapshotRetentionPreference() async {
    _snapshotRetentionEnabled = await _prefs.getSnapshotRetentionEnabled();
    notifyListeners();
  }

  Future<void> setSnapshotRetentionEnabled(bool value) async {
    await _prefs.setSnapshotRetentionEnabled(value);
    _snapshotRetentionEnabled = value;
    notifyListeners();
  }

  Future<void> loadProcessingDelayPreference() async {
    _processingDelay = await _prefs.getProcessingDelay();
    notifyListeners();
  }

  Future<void> setProcessingDelay(int value) async {
    await _prefs.setProcessingDelay(value);
    _processingDelay = value;
    notifyListeners();
  }

  Future<void> loadQueueResumedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _queueResumed = prefs.getBool(_queueResumedKey) ?? false;
    notifyListeners();
  }

  Future<void> setEvaluationQueueResumed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_queueResumedKey, value);
    _queueResumed = value;
    notifyListeners();
  }
}
