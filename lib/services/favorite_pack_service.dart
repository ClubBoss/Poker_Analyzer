import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';

class FavoritePackService {
  FavoritePackService._();
  static final instance = FavoritePackService._();
  static const _key = 'favorite_packs';

  final _ctrl = StreamController<Set<String>>.broadcast();
  Set<String> _ids = {};

  Stream<Set<String>> get favorites$ => _ctrl.stream;

  Future<void> init() async {
    final prefs = await PreferencesService.getInstance();
    _ids = prefs.getStringList(_key)?.toSet() ?? {};
    _ctrl.add(Set.from(_ids));
  }

  Future<void> toggle(String id) async {
    if (!_ids.add(id)) {
      _ids.remove(id);
    }
    final prefs = await PreferencesService.getInstance();
    await prefs.setStringList(_key, _ids.toList());
    _ctrl.add(Set.from(_ids));
  }

  bool isFavorite(String id) => _ids.contains(id);
}
