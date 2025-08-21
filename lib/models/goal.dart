enum GoalType { daily, weekly, progressive }

class Goal {
  final String id;
  final String title;
  final GoalType type;
  final int targetXP;
  int currentXP;
  final DateTime deadline;
  final int reward;
  bool completed;

  Goal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetXP,
    this.currentXP = 0,
    required this.deadline,
    this.reward = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'targetXP': targetXP,
    'currentXP': currentXP,
    'deadline': deadline.toIso8601String(),
    'reward': reward,
    'completed': completed,
  };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
    id: json['id'] as String,
    title: json['title'] as String,
    type: GoalType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => GoalType.daily,
    ),
    targetXP: json['targetXP'] as int,
    currentXP: json['currentXP'] as int? ?? 0,
    deadline:
        DateTime.tryParse(json['deadline'] as String? ?? '') ?? DateTime.now(),
    reward: json['reward'] as int? ?? 0,
    completed: json['completed'] as bool? ?? false,
  );
}
