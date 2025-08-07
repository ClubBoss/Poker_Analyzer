import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/auto_skill_gap_clusterer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects weak skill clusters and sorts by severity', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final clusterer = AutoSkillGapClusterer(prefs: prefs);
    const history = UserSkillHistory(
      tagAccuracy: {
        'pushfold_sb': 0.5,
        'pushfold_bb': 0.6,
        'icm_shove': 0.65,
        'postflop_jam': 0.8,
      },
      tagOccurrences: {
        'pushfold_sb': 10,
        'pushfold_bb': 5,
        'icm_shove': 8,
        'postflop_jam': 10,
      },
      tagCategories: {
        'pushfold_sb': 'push-fold',
        'pushfold_bb': 'push-fold',
        'icm_shove': 'ICM',
        'postflop_jam': 'postflop-jam',
      },
    );

    final clusters = await clusterer.detectWeakSkillClusters(history);
    expect(clusters.length, 2);
    expect(clusters.first.clusterName, 'push-fold');
    expect(clusters.first.tags, containsAll(['pushfold_sb', 'pushfold_bb']));
    expect(clusterer.clustersNotifier.value, clusters);
  });
}
