import 'player_model.dart';

Map<int, int> _intIntMapFromJson(Map<String, dynamic> json) =>
    json.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
Map<String, int> _intIntMapToJson(Map<int, int> map) =>
    map.map((k, v) => MapEntry(k.toString(), v));
Map<int, int>? _intIntMapFromJsonNullable(Map<String, dynamic>? json) =>
    json?.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
Map<String, int>? _intIntMapToJsonNullable(Map<int, int>? map) =>
    map?.map((k, v) => MapEntry(k.toString(), v));
Map<int, String> _intStringMapFromJson(Map<String, dynamic> json) =>
    json.map((k, v) => MapEntry(int.parse(k), v as String));
Map<String, String> _intStringMapToJson(Map<int, String> map) =>
    map.map((k, v) => MapEntry(k.toString(), v));
Map<int, String>? _intStringMapFromJsonNullable(Map<String, dynamic>? json) =>
    json?.map((k, v) => MapEntry(int.parse(k), v as String));
Map<String, String>? _intStringMapToJsonNullable(Map<int, String>? map) =>
    map?.map((k, v) => MapEntry(k.toString(), v));
Map<int, String?>? _intNullableStringMapFromJson(Map<String, dynamic>? json) =>
    json?.map((k, v) => MapEntry(int.parse(k), v as String?));
Map<String, String?>? _intNullableStringMapToJson(Map<int, String?>? map) =>
    map?.map((k, v) => MapEntry(k.toString(), v));
Map<int, PlayerType>? _playerTypeMapFromJson(Map<String, dynamic>? json) =>
    json?.map((k, v) => MapEntry(
        int.parse(k),
        PlayerType.values.firstWhere(
          (e) => e.name == v,
          orElse: () => PlayerType.unknown,
        )));
Map<String, String>? _playerTypeMapToJson(Map<int, PlayerType>? map) =>
    map?.map((k, v) => MapEntry(k.toString(), v.name));
