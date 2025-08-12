import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/training_pack_template.dart';
import 'package:poker_analyzer/services/sr_queue_builder.dart';
import 'package:poker_analyzer/services/spaced_review_service.dart';
import 'package:poker_analyzer/services/template_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildSrQueue skips duplicates and exhausts', () async {
    final storage = TemplateStorageService();
    final spot1 = TrainingPackSpot(id: 's1');
    final spot2 = TrainingPackSpot(id: 's2');
    storage.addTemplate(
      TrainingPackTemplate(
        id: 'p1',
        name: 'P1',
        createdAt: DateTime.now(),
        spots: [spot1, spot2],
      ),
    );
    final svc = SpacedReviewService(templates: storage);
    await svc.recordMistake('s1', 'p1');
    final queue = buildSrQueue(
      svc,
      {'s2'},
      now: DateTime.now().add(const Duration(days: 1)),
    );
    expect(queue.length, 1);
    expect(queue.first.spot.id, 's1');
    queue.removeAt(0);
    expect(queue.isEmpty, true);
  });
}
