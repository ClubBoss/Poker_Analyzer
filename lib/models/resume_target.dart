enum ResumeType { lesson, pack, block }

class ResumeTarget {
  final String id;
  final ResumeType type;
  const ResumeTarget(this.id, this.type);
}
