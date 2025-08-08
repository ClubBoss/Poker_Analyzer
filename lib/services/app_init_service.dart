import 'yaml_pack_archive_auto_cleaner_service.dart';
import 'theory_injection_scheduler_service.dart';
import 'theory_integrity_sweep_scheduler_service.dart';
import 'config_source.dart';
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
    final prefMap = {for (var k in prefs.getKeys()) k: prefs.get(k)};
    final config = await ConfigSource.from(prefs: prefMap);
    await TheoryInjectionSchedulerService.instance.start();
    await TheoryIntegritySweepSchedulerService.instance.start(config: config);
  }
}
