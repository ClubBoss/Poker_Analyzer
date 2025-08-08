import 'yaml_pack_archive_auto_cleaner_service.dart';
import 'theory_injection_scheduler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppInitService {
  AppInitService._();
  static final instance = AppInitService._();

  Future<void> init() async {
    await const YamlPackArchiveAutoCleanerService().clean();
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().toList()) {
      if (k.startsWith('theory.cap.session.')) {
        await prefs.remove(k);
      }
    }
    await TheoryInjectionSchedulerService.instance.start();
  }
}
