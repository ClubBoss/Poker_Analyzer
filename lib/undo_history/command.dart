import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

@immutable
class Command {
  final String type;
  final Map<String, dynamic>? payload;
  final DateTime time;

  const Command(
    this.type, {
    this.payload,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        if (payload != null) 'payload': payload,
        'time': time.toIso8601String(),
      };

  factory Command.fromJson(Map<String, dynamic> json) => Command(
        json['type'] as String,
        payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
        time: DateTime.parse(json['time'] as String),
      );

  static const _mapEquality = MapEquality<String, dynamic>();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Command &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          _mapEquality.equals(payload, other.payload) &&
          time == other.time;

  @override
  int get hashCode => Object.hash(type, _mapEquality.hash(payload), time);
}
