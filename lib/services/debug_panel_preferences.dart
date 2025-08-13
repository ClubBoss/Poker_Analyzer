import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/action_evaluation_request.dart';

class DebugPanelPreferences extends ChangeNotifier {
  static const _snapshotRetentionKey = 'snapshot_retention_enabled';
  static const _processingDelayKey = 'evaluation_processing_delay';
  static const _queueFilterKey = 'evaluation_queue_filter';
  static const _advancedFilterKey = 'evaluation_advanced_filters';
  static const _sortBySprKey = 'evaluation_sort_by_spr';
  static const _searchQueryKey = 'evaluation_search_query';

  static const _queueResumedKey = 'evaluation_queue_resumed';
  static const _debugPanelOpenKey = 'debug_panel_open';
  static const _debugLayoutKey = 'debug_layout_enabled';
  static const _showAllCardsKey = 'show_all_revealed_cards';
  static const _pinHeroKey = 'pin_hero_position';

  bool _snapshotRetentionEnabled = true;
  int _processingDelay = 500;
  Set<String> _queueFilters = {'pending'};
  Set<String> _advancedFilters = {};
  bool _sortBySpr = false;
  String _searchQuery = '';
  bool _queueResumed = false;
  bool _isDebugPanelOpen = false;
  bool _debugLayout = false;
  bool _showAllRevealedCards = false;
  bool _pinHeroPosition = false;

  bool get snapshotRetentionEnabled => _snapshotRetentionEnabled;
  int get processingDelay => _processingDelay;
  Set<String> get queueFilters => _queueFilters;
  Set<String> get advancedFilters => _advancedFilters;
  bool get sortBySpr => _sortBySpr;
  String get searchQuery => _searchQuery;
  bool get queueResumed => _queueResumed;
  bool get isDebugPanelOpen => _isDebugPanelOpen;
  bool get debugLayout => _debugLayout;
  bool get showAllRevealedCards => _showAllRevealedCards;
  bool get pinHeroPosition => _pinHeroPosition;

  Future<void> loadSnapshotRetention() async {
    final prefs = await SharedPreferences.getInstance();
    _snapshotRetentionEnabled = prefs.getBool(_snapshotRetentionKey) ?? true;
  }

  Future<void> setSnapshotRetentionEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_snapshotRetentionKey, value);
    _snapshotRetentionEnabled = value;
    notifyListeners();
  }

  Future<void> loadProcessingDelay() async {
    final prefs = await SharedPreferences.getInstance();
    _processingDelay =
        (prefs.getInt(_processingDelayKey) ?? 500).clamp(100, 2000);
  }

  Future<void> setProcessingDelay(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_processingDelayKey, value);
    _processingDelay = value;
    notifyListeners();
  }

  Future<void> loadQueueFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_queueFilterKey);
    final filters = list?.toSet() ?? {'pending'};
    _queueFilters = filters.isEmpty ? {'pending'} : filters;
  }

  Future<void> setQueueFilters(Set<String> value) async {
    if (value.isEmpty) value = {'pending'};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_queueFilterKey, value.toList());
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

  Future<void> loadAdvancedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_advancedFilterKey);
    _advancedFilters = list?.toSet() ?? {};
  }

  Future<void> setAdvancedFilters(Set<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_advancedFilterKey, value.toList());
    _advancedFilters = value;
    notifyListeners();
  }

  Future<void> loadSortBySpr() async {
    final prefs = await SharedPreferences.getInstance();
    _sortBySpr = prefs.getBool(_sortBySprKey) ?? false;
  }

  Future<void> setSortBySpr(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sortBySprKey, value);
    _sortBySpr = value;
    notifyListeners();
  }

  Future<void> loadSearchQuery() async {
    final prefs = await SharedPreferences.getInstance();
    _searchQuery = prefs.getString(_searchQueryKey) ?? '';
  }

  Future<void> setSearchQuery(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_searchQueryKey, value);
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> loadQueueResumed() async {
    final prefs = await SharedPreferences.getInstance();
    _queueResumed = prefs.getBool(_queueResumedKey) ?? false;
  }

  Future<void> setEvaluationQueueResumed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_queueResumedKey, value);
    _queueResumed = value;
    notifyListeners();
  }

  Future<void> loadDebugPanelOpen() async {
    final prefs = await SharedPreferences.getInstance();
    _isDebugPanelOpen = prefs.getBool(_debugPanelOpenKey) ?? false;
  }

  Future<void> setIsDebugPanelOpen(bool value) async {
    if (_isDebugPanelOpen == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugPanelOpenKey, value);
    _isDebugPanelOpen = value;
    notifyListeners();
  }

  Future<void> loadDebugLayout() async {
    final prefs = await SharedPreferences.getInstance();
    _debugLayout = prefs.getBool(_debugLayoutKey) ?? false;
  }

  Future<void> setDebugLayout(bool value) async {
    if (_debugLayout == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_debugLayoutKey, value);
    _debugLayout = value;
    notifyListeners();
  }

  Future<void> loadShowAllRevealedCards() async {
    final prefs = await SharedPreferences.getInstance();
    _showAllRevealedCards = prefs.getBool(_showAllCardsKey) ?? false;
  }

  Future<void> setShowAllRevealedCards(bool value) async {
    if (_showAllRevealedCards == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showAllCardsKey, value);
    _showAllRevealedCards = value;
    notifyListeners();
  }

  Future<void> loadPinHeroPosition() async {
    final prefs = await SharedPreferences.getInstance();
    _pinHeroPosition = prefs.getBool(_pinHeroKey) ?? false;
  }

  Future<void> setPinHeroPosition(bool value) async {
    if (_pinHeroPosition == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinHeroKey, value);
    _pinHeroPosition = value;
    notifyListeners();
  }

  List<T> applyAdvancedFilters<T extends ActionEvaluationRequest>(
      List<T> list) {
    final filters = _advancedFilters;
    final sort = _sortBySpr;
    final search = _searchQuery.trim().toLowerCase();
    if (filters.isEmpty && !sort && search.isEmpty) return list;

    final checkFeedback = filters.contains('feedback');
    final checkOpponent = filters.contains('opponent');
    final checkFailed = filters.contains('failed');
    final checkHighSpr = filters.contains('highspr');
    final searchActive = search.isNotEmpty;

    final shouldFilter = checkFeedback ||
        checkOpponent ||
        checkFailed ||
        checkHighSpr ||
        searchActive;

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

  Future<void> loadAllPreferences() async {
    await loadSnapshotRetention();
    await loadProcessingDelay();
    await loadQueueFilters();
    await loadAdvancedFilters();
    await loadSearchQuery();
    await loadSortBySpr();
    await loadQueueResumed();
    await loadDebugPanelOpen();
    await loadDebugLayout();
    await loadShowAllRevealedCards();
    await loadPinHeroPosition();
    notifyListeners();
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotRetentionKey);
    await prefs.remove(_processingDelayKey);
    await prefs.remove(_queueFilterKey);
    await prefs.remove(_advancedFilterKey);
    await prefs.remove(_sortBySprKey);
    await prefs.remove(_searchQueryKey);
    await prefs.remove(_debugPanelOpenKey);
    await prefs.remove(_debugLayoutKey);
    await prefs.remove(_showAllCardsKey);
    await prefs.remove(_pinHeroKey);
    _queueResumed = prefs.getBool(_queueResumedKey) ?? false;
    await loadAllPreferences();
  }
}
