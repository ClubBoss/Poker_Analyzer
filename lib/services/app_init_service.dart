import 'yaml_pack_archive_auto_cleaner_service.dart';

class AppInitService {
  AppInitService._();
  static final instance = AppInitService._();

  Future<void> init() async {
    await const YamlPackArchiveAutoCleanerService().clean();
  }
}
