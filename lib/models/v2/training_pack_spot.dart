class TrainingPackSpot {
  final String id;
  String title;
  String note;

  TrainingPackSpot({required this.id, this.title = '', this.note = ''});

  TrainingPackSpot copyWith({String? id, String? title, String? note}) =>
      TrainingPackSpot(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note ?? this.note,
      );

  factory TrainingPackSpot.fromJson(Map<String, dynamic> j) => TrainingPackSpot(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        note: j['note'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'note': note};
}
