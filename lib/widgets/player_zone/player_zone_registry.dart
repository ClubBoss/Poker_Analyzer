part of 'player_zone_core.dart';

class PlayerZoneRegistry {
  final Map<String, _PlayerZoneWidgetState> _states = {};

  void register(String name, _PlayerZoneWidgetState state) => _states[name] = state;

  void unregister(String name) => _states.remove(name);

  _PlayerZoneWidgetState? operator [](String name) => _states[name];

  Iterable<_PlayerZoneWidgetState> get values => _states.values;
}
