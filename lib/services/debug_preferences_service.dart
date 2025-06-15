import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/debug_panel_preferences.dart';
import '../models/action_evaluation_request.dart';

class DebugPreferencesService extends ChangeNotifier {
  static const _queueResumedKey = 'evaluation_queue_resumed';
  static const _debugPanelOpenKey = 'debug_panel_open';
  static const _debugLayoutKey = 'debug_layout_enabled';
  static const _showAllCardsKey = 'show_all_revealed_cards';

  final DebugPanelPreferences _prefs = DebugPanelPreferences();

  bool _snapshotRetentionEnabled = true;
  int _processingDelay = 500;
  bool _sortBySpr = false;
  String _searchQuery = '';
  bool _queueResumed = false;
  bool _isDebugPanelOpen = false;
  bool _debugLayout = false;
  bool _showAllRevealedCards = false;
  Set<String> _queueFilters = {'pending'};
  Set<String> _advancedFilters = {};

  bool get snapshotRetentionEnabled => _snapshotRetentionEnabled;
  int get processingDelay => _processingDelay;
  bool get sortBySpr => _sortBySpr;
  String get searchQuery => _searchQuery;
  bool get queueResumed => _queueResumed;
  bool get isDebugPanelOpen => _isDebugPanelOpen;
  bool get debugLayout => _debugLayout;
  bool get showAllRevealedCards => _showAllRevealedCards;
  Set<String> get queueFilters => _queueFilters;
  Set<String> get advancedFilters => _advancedFilters;

  Future<void> setIsDebugPanelOpen(bool value) async {
    if (_isDebugPanelOpen == value) return;
    _isDebugPanelOpen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPanelOpenKey, value);
    notifyListeners();
  }

  Future<void> loadDebugLayoutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _debugLayout = prefs.getBool(_debugLayoutKey) ?? false;
    notifyListeners();
  }

  Future<void> setDebugLayout(bool value) async {
    if (_debugLayout == value) return;
    _debugLayout = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugLayoutKey, value);
    notifyListeners();
  }

  Future<void> loadShowAllRevealedCardsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _showAllRevealedCards = prefs.getBool(_showAllCardsKey) ?? false;
    notifyListeners();
  }

  Future<void> setShowAllRevealedCards(bool value) async {
    if (_showAllRevealedCards == value) return;
    _showAllRevealedCards = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAllCardsKey, value);
    notifyListeners();
  }

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

  Future<void> loadQueueFilterPreference() async {
    _queueFilters = await _prefs.getQueueFilters();
    notifyListeners();
  }

  Future<void> setQueueFilters(Set<String> value) async {
    await _prefs.setQueueFilters(value);
    _queueFilters = value.isEmpty ? {'pending'} : value;
    notifyListeners();
  }

  void toggleQueueFilter(String filter) {
    final updated = Set<String>.from(_queueFilters);
    if (updated.contains(filter)) {
      updated.remove(filter);
    } else {
      updated.add(filter);
    }
    setQueueFilters(updated);
  }

  Future<void> loadAdvancedFilterPreference() async {
    _advancedFilters = await _prefs.getAdvancedFilters();
    notifyListeners();
  }

  Future<void> setAdvancedFilters(Set<String> value) async {
    await _prefs.setAdvancedFilters(value);
    _advancedFilters = value;
    notifyListeners();
  }

  List<T> applyAdvancedFilters<T extends ActionEvaluationRequest>(List<T> list) {
    final filters = _advancedFilters;
    final sort = _sortBySpr;
    final search = _searchQuery.trim().toLowerCase();
    if (filters.isEmpty && !sort && search.isEmpty) return list;

    final checkFeedback = filters.contains('feedback');
    final checkOpponent = filters.contains('opponent');
    final checkFailed = filters.contains('failed');
    final checkHighSpr = filters.contains('highspr');
    final searchActive = search.isNotEmpty;

    final shouldFilter =
        checkFeedback || checkOpponent || checkFailed || checkHighSpr || searchActive;

    if (!shouldFilter && !sort) {
      return list;
    }

    bool matches(ActionEvaluationRequest r) {
      final md = r.metadata;

      if (checkFeedback) {
        final text = md?['feedbackText'] as String?;
        if (text == null || text.isEmpty) return false;
      }

      if (checkOpponent && ((md?['opponentCards'] as List?)?.isEmpty ?? true)) {
        return false;
      }

      if (checkFailed && md?['status'] != 'failed') return false;

      if (checkHighSpr) {
        final spr = (md?['spr'] as num?)?.toDouble();
        if (spr == null || spr < 3) return false;
      }

      if (searchActive) {
        final feedback = (md?['feedbackText'] as String?) ?? '';
        final id = r.id;
        if (!id.toLowerCase().contains(search) &&
            !feedback.toLowerCase().contains(search)) {
          return false;
        }
      }

      return true;
    }

    final filtered = <T>[];
    var modified = false;
    for (final r in list) {
      if (matches(r)) {
        filtered.add(r);
      } else {
        modified = true;
      }
    }

    var result = modified ? filtered : list;

    if (sort) {
      final sorted = List<T>.from(result);
      sorted.sort((a, b) {
        final sa = (a.metadata?['spr'] as num?)?.toDouble() ?? -double.infinity;
        final sb = (b.metadata?['spr'] as num?)?.toDouble() ?? -double.infinity;
        return sb.compareTo(sa);
      });
      result = sorted;
    }

    return result;
  }

  void toggleAdvancedFilter(String filter) {
    final updated = Set<String>.from(_advancedFilters);
    if (updated.contains(filter)) {
      updated.remove(filter);
    } else {
      updated.add(filter);
    }
    setAdvancedFilters(updated);
  }

  Future<void> loadQueueResumedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _queueResumed = prefs.getBool(_queueResumedKey) ?? false;
    notifyListeners();
  }

  Future<void> loadDebugPanelOpenPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDebugPanelOpen = prefs.getBool(_debugPanelOpenKey) ?? false;
    notifyListeners();
  }

  /// Loads all stored debug preferences.
  Future<void> loadAllPreferences() async {
    await loadSnapshotRetentionPreference();
    await loadProcessingDelayPreference();
    await loadQueueFilterPreference();
    await loadAdvancedFilterPreference();
    await loadSearchQueryPreference();
    await loadSortBySprPreference();
    await loadQueueResumedPreference();
    await loadDebugPanelOpenPreference();
    await loadDebugLayoutPreference();
    await loadShowAllRevealedCardsPreference();
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
    _queueFilters = await _prefs.getQueueFilters();
    _advancedFilters = await _prefs.getAdvancedFilters();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_debugPanelOpenKey);
    await prefs.remove(_debugLayoutKey);
    await prefs.remove(_showAllCardsKey);
    _queueResumed = prefs.getBool(_queueResumedKey) ?? false;
    _isDebugPanelOpen = prefs.getBool(_debugPanelOpenKey) ?? false;
    _debugLayout = prefs.getBool(_debugLayoutKey) ?? false;
    _showAllRevealedCards = prefs.getBool(_showAllCardsKey) ?? false;
    notifyListeners();
  }
}
