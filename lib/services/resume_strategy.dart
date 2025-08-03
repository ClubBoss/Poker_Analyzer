import '../models/resume_target.dart';

abstract class ResumeStrategy {
  Future<ResumeTarget?> getResumeTarget();
}
