import '../action_entry.dart';

class HandData {
  String heroCards;
  Map<int, List<ActionEntry>> actions;
  String position;
  Map<String, double> stacks;

  HandData({
    this.heroCards = '',
    this.position = '',
    Map<int, List<ActionEntry>>? actions,
    Map<String, double>? stacks,
  })  : actions =
            actions ?? {for (var s = 0; s < 4; s++) s: <ActionEntry>[]},
        stacks = stacks ?? {};

  factory HandData.fromJson(Map<String, dynamic> j) {
    final acts = <int, List<ActionEntry>>{for (var s = 0; s < 4; s++) s: []};
    if (j['actions'] != null) {
      (j['actions'] as Map).forEach((key, value) {
        acts[int.parse(key as String)] = [
          for (final a in (value as List))
            ActionEntry.fromJson(Map<String, dynamic>.from(a))
        ];
      });
    }
    if (acts.values.every((l) => l.isEmpty) && j['streetActions'] != null) {
      final list = j['streetActions'] as List?;
      if (list != null && list.isNotEmpty) {
        acts[0] = [
          ActionEntry(0, 0, 'note', customLabel: list.first as String)
        ];
      }
    }
    return HandData(
      heroCards: j['heroCards'] as String? ?? '',
      position: j['position'] as String? ?? '',
      actions: acts,
      stacks: Map<String, double>.from(j['stacks'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'heroCards': heroCards,
        'position': position,
        if (actions.values.any((l) => l.isNotEmpty))
          'actions': {
            for (final kv in actions.entries)
              kv.key.toString(): [for (final a in kv.value) a.toJson()]
          },
        if (stacks.isNotEmpty) 'stacks': stacks,
      };
}
