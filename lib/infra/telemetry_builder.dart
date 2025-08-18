Map<String, dynamic> buildTelemetry({
  required String sessionId,
  String? packId,
  Map<String, dynamic>? data,
}) {
  bool isAscii(String s) => s.codeUnits.every((c) => c < 128);
  final m = <String, dynamic>{'sessionId': sessionId};
  if (packId != null && packId.isNotEmpty) m['packId'] = packId;
  if (data != null) {
    final d = <String, dynamic>{};
    data.forEach((key, value) {
      if (key == 'sessionId' || key == 'packId') return;
      if (isAscii(key)) d[key] = value;
    });
    m.addAll(d);
  }
  return m;
}

Map<String, Object?> buildTheoryViewed({
  required String moduleId,
  required String theoryId,
}) {
  return {'moduleId': moduleId, 'theoryId': theoryId};
}

Map<String, Object?> buildDemoCompleted({
  required String moduleId,
  required String demoId,
  int? ms,
}) {
  final m = <String, Object?>{'moduleId': moduleId, 'demoId': demoId};
  if (ms != null) m['ms'] = ms;
  return m;
}

Map<String, Object?> buildPracticeSpotAnswered({
  required String moduleId,
  required String spotId,
  required bool correct,
  required int ms,
  String? kind,
}) {
  final m = <String, Object?>{
    'moduleId': moduleId,
    'spotId': spotId,
    'correct': correct,
    'ms': ms,
  };
  if (kind != null) m['kind'] = kind;
  return m;
}

Map<String, Object?> buildModuleMastered({required String moduleId}) {
  return {'moduleId': moduleId};
}
