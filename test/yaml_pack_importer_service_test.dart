import 'package:test/test.dart';
import 'package:poker_analyzer/services/yaml_pack_importer_service.dart';

void main() {
  test('loadFromYaml returns templates', () async {
    final service = YamlPackImporterService();
    final list = await service.loadFromYaml('pack_templates.yaml');
    expect(list, isNotEmpty);
  });
}
