class Command {
  final String type;
  final Map<String, dynamic>? payload;
  final DateTime time;

  Command(this.type, {this.payload}) : time = DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type,
        if (payload != null) 'payload': payload,
        'time': time.toIso8601String(),
      };

  factory Command.fromJson(Map<String, dynamic> json) => Command(
        json['type'] as String,
        payload: (json['payload'] as Map?)?.cast<String, dynamic>(),
      );
}
