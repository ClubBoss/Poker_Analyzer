import 'package:test/test.dart';

import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';
import 'package:poker_analyzer/models/autogen_session_meta.dart';

void main() {
  final service = AutogenStatusDashboardService.instance;

  setUp(() => service.clear());

  tearDown(() => service.clear());

  test('registers and updates sessions', () {
    final meta = AutogenSessionMeta(
      sessionId: 's1',
      packId: 'p1',
      startedAt: DateTime.now(),
      status: 'running',
    );
    service.registerSession(meta);
    expect(service.getRecentSessions(), hasLength(1));
    expect(service.getRecentSessions().first.status, 'running');

    service.updateSessionStatus('s1', 'done');
    expect(service.getRecentSessions().first.status, 'done');
  });

  test('removes sessions older than 24 hours', () {
    final old = AutogenSessionMeta(
      sessionId: 'old',
      packId: 'p',
      startedAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'done',
    );
    final recent = AutogenSessionMeta(
      sessionId: 'new',
      packId: 'p',
      startedAt: DateTime.now(),
      status: 'running',
    );
    service.registerSession(old);
    service.registerSession(recent);
    final sessions = service.getRecentSessions();
    expect(sessions, hasLength(1));
    expect(sessions.first.sessionId, 'new');
  });

  test('tracks duplicate packs', () {
    service.flagDuplicate('c1', 'e1', 'duplicate', 1.0);
    expect(service.duplicates, hasLength(1));
    final info = service.duplicates.first;
    expect(info.candidateId, 'c1');
    expect(info.existingId, 'e1');
    expect(info.reason, 'duplicate');
  });
}
