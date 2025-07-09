import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_pack_template_service.dart';

void main() {
  testWidgets('built-in template exists', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final list = TrainingPackTemplateService.getAllTemplates(tester.element(find.byType(SizedBox)));
    expect(list, isNotEmpty);
    expect(list.first.spots, isNotEmpty);
  });
}
