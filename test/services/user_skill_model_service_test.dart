import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/user_skill_model_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recordAttempt updates mastery and confidence', () async {
    const user = 'u1';
    await UserSkillModelService.instance
        .recordAttempt(user, ['tag1'], correct: true);
    var skills = await UserSkillModelService.instance.getSkills(user);
    final first = skills['tag1']!;
    await UserSkillModelService.instance
        .recordAttempt(user, ['tag1'], correct: true);
    skills = await UserSkillModelService.instance.getSkills(user);
    final second = skills['tag1']!;
    expect(second.mastery, greaterThan(first.mastery));
    expect(second.confidence, greaterThan(first.confidence));
  });

  test('decayTick lowers mastery for stale tags', () async {
    const user = 'u2';
    await UserSkillModelService.instance
        .recordAttempt(user, ['tag2'], correct: true);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('skillModel.$user');
    final data = jsonDecode(raw!) as Map<String, dynamic>;
    final skill = Map<String, dynamic>.from(data['tag2'] as Map);
    skill['lastSeen'] =
        DateTime.now().subtract(const Duration(days: 40)).toIso8601String();
    data['tag2'] = skill;
    await prefs.setString('skillModel.$user', jsonEncode(data));
    final before =
        (await UserSkillModelService.instance.getSkills(user))['tag2']!.mastery;
    await UserSkillModelService.instance.decayTick(user);
    final after =
        (await UserSkillModelService.instance.getSkills(user))['tag2']!.mastery;
    expect(after, lessThan(before));
  });
}
