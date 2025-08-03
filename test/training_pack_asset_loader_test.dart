import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/training_pack_asset_loader.dart';
import 'package:poker_analyzer/services/training_pack_template_service.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads starter pushfold template from assets', () async {
    await TrainingPackAssetLoader.instance.loadAll();
    final tpl = TrainingPackTemplateService.starterPushfold10bb();
    expect(tpl.id, 'starter_pushfold_10bb');
    expect(tpl.spots.length, 10);
    expect(tpl.heroPos, HeroPosition.sb);
  });
}
