class Goal {
  final String id;
  final String title;
  final String type;
  final int target;
  int progress;
  final int reward;
  bool completed;

  Goal({
    required this.id,
    required this.title,
    required this.type,
    required this.target,
    this.progress = 0,
    this.reward = 0,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'target': target,
        'progress': progress,
        'reward': reward,
        'completed': completed,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        title: json['title'] as String,
        type: json['type'] as String,
        target: json['target'] as int,
        progress: json['progress'] as int? ?? 0,
        reward: json['reward'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}
