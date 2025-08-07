class AutogenSessionMeta {
  final String sessionId;
  final String packId;
  final DateTime startedAt;
  final String status; // running, done, error

  AutogenSessionMeta({
    required this.sessionId,
    required this.packId,
    required this.startedAt,
    required this.status,
  });

  AutogenSessionMeta copyWith({
    String? sessionId,
    String? packId,
    DateTime? startedAt,
    String? status,
  }) {
    return AutogenSessionMeta(
      sessionId: sessionId ?? this.sessionId,
      packId: packId ?? this.packId,
      startedAt: startedAt ?? this.startedAt,
      status: status ?? this.status,
    );
  }
}
