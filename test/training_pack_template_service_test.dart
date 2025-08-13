import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_pack_template_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starter pack names default to English', () {
    final packs = TrainingPackTemplateService.getAllTemplates();
    expect(packs.first.name, 'Push/Fold 10BB (No Ante)');
    expect(packs[1].name, 'Push/Fold 12BB (No Ante)');
    expect(packs.last.name, 'Push/Fold 15BB (No Ante)');
  });

  testWidgets('starter pack names localize', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    final packs = TrainingPackTemplateService.getAllTemplates(ctx);
    expect(packs.first.name, AppLocalizations.of(ctx)!.packPushFold10);
    expect(packs[1].name, AppLocalizations.of(ctx)!.packPushFold12);
    expect(packs.last.name, AppLocalizations.of(ctx)!.packPushFold15);
  });
}
