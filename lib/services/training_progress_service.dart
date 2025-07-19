import 'package:shared_preferences/shared_preferences.dart';
import 'training_pack_template_service.dart';

class TrainingProgressService {
  TrainingProgressService._();
  static final instance = TrainingProgressService._();

  Future<double> getProgress(String templateId) async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt('tpl_prog_$templateId') ??
        prefs.getInt('progress_tpl_$templateId');
    if (idx == null) return 0.0;
    final tpl = TrainingPackTemplateService.getById(templateId);
    if (tpl == null) return 0.0;
    final count = tpl.spots.isNotEmpty ? tpl.spots.length : tpl.spotCount;
    if (count == 0) return 0.0;
    return ((idx + 1) / count).clamp(0.0, 1.0);
  }
}
