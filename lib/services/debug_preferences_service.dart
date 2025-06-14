import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/debug_panel_preferences.dart';

class DebugPreferencesService extends ChangeNotifier {
  static const _queueResumedKey = 'evaluation_queue_resumed';

  final DebugPanelPreferences _prefs = DebugPanelPreferences();

  bool _snapshotRetentionEnabled = true;
  int _processingDelay = 500;
  bool _sortBySpr = false;
  String _searchQuery = '';
  bool _queueResumed = false;

  bool get snapshotRetentionEnabled => _snapshotRetentionEnabled;
  int get processingDelay => _processingDelay;
  bool get sortBySpr => _sortBySpr;
  String get searchQuery => _searchQuery;
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

  Future<void> loadSortBySprPreference() async {
    _sortBySpr = await _prefs.getSortBySpr();
    notifyListeners();
  }

  Future<void> setSortBySpr(bool value) async {
    await _prefs.setSortBySpr(value);
    _sortBySpr = value;
    notifyListeners();
  }

  Future<void> loadSearchQueryPreference() async {
    _searchQuery = await _prefs.getSearchQuery();
    notifyListeners();
  }

  Future<void> setSearchQuery(String value) async {
    await _prefs.setSearchQuery(value);
    _searchQuery = value;
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

  Future<void> clearAll() async {
    await _prefs.clearAll();
    _snapshotRetentionEnabled = await _prefs.getSnapshotRetentionEnabled();
    _processingDelay = await _prefs.getProcessingDelay();
    _sortBySpr = await _prefs.getSortBySpr();
    _searchQuery = await _prefs.getSearchQuery();
    notifyListeners();
  }
}
