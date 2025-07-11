class CategoryProgress {
  int played;
  int correct;
  double evLost;
  double evSaved;
  CategoryProgress({
    this.played = 0,
    this.correct = 0,
    this.evLost = 0,
    this.evSaved = 0,
  });
  Map<String, dynamic> toJson() => {
        'played': played,
        'correct': correct,
        if (evLost != 0) 'evLost': evLost,
        if (evSaved != 0) 'evSaved': evSaved,
      };
  factory CategoryProgress.fromJson(Map<String, dynamic> j) => CategoryProgress(
        played: (j['played'] as num?)?.toInt() ?? 0,
        correct: (j['correct'] as num?)?.toInt() ?? 0,
        evLost: (j['evLost'] as num?)?.toDouble() ?? 0,
        evSaved: (j['evSaved'] as num?)?.toDouble() ?? 0,
      );
}
