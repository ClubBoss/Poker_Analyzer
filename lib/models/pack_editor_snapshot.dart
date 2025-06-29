import "package:uuid/uuid.dart";
import "saved_hand.dart";
import "view_preset.dart";

class PackEditorSnapshot {
  final String id;
  final String name;
  final DateTime timestamp;
  final List<SavedHand> hands;
  final List<ViewPreset> views;
  final Map<String, dynamic> filters;
  final bool isAuto;

  PackEditorSnapshot({
    String? id,
    required this.name,
    DateTime? timestamp,
    required this.hands,
    required this.views,
    required this.filters,
    this.isAuto = false,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timestamp': timestamp.toIso8601String(),
        'hands': [for (final h in hands) h.toJson()],
        'views': [for (final v in views) v.toJson()],
        'filters': filters,
        'isAuto': isAuto,
      };

  factory PackEditorSnapshot.fromJson(Map<String, dynamic> json) =>
      PackEditorSnapshot(
        id: json['id'] as String?,
        name: json['name'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.now(),
        hands: [
          for (final h in (json['hands'] as List? ?? []))
            SavedHand.fromJson(Map<String, dynamic>.from(h as Map))
        ],
        views: [
          for (final v in (json['views'] as List? ?? []))
            ViewPreset.fromJson(Map<String, dynamic>.from(v as Map))
        ],
        filters: Map<String, dynamic>.from(json['filters'] as Map? ?? {}),
        isAuto: json['isAuto'] as bool? ?? false,
      );

  PackEditorSnapshot copyWith({String? name}) => PackEditorSnapshot(
        id: id,
        name: name ?? this.name,
        timestamp: timestamp,
        hands: hands,
        views: views,
        filters: filters,
        isAuto: isAuto,
      );
}
