import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/core/models/spot_seed/seed_issue.dart';
import 'package:poker_analyzer/services/autogen_status_dashboard_service.dart';

void main() {
  test('reportSeedIssues updates notifier', () {
    final service = AutogenStatusDashboardService.instance;
    service.clear();
    service.reportSeedIssues('s1', [
      const SeedIssue(code: 'c', severity: 'warn', message: 'm'),
    ]);
    expect(service.seedIssuesNotifier.value.length, 1);
    final issue = service.seedIssuesNotifier.value.first;
    expect(issue.seedId, 's1');
  });
}
