import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_classifier_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';

void main() {
  const service = BoardTextureClassifierService();

  test('classifies spots and caches tags', () {
    final spots = [
      TrainingPackSpot(id: 's1', board: ['As', 'Ah', 'Td']),
      TrainingPackSpot(id: 's2', board: ['2c', '3c', '4c']),
      TrainingPackSpot(id: 's3', board: ['As', 'Ks', '4h']),
    ];
    final result = service.classify(spots);

    expect(
      result['s1']!.toSet(),
      containsAll({'aceHigh', 'paired', 'rainbow', 'connected', 'wet'}),
    );
    expect(
      result['s2']!.toSet(),
      containsAll({'low', 'monotone', 'connected', 'wet'}),
    );
    expect(result['s3']!.toSet(), containsAll({'aceHigh', 'twoTone', 'wet'}));
    expect(spots[0].meta['boardTextureTags'], result['s1']);
    expect(spots[1].meta['boardTextureTags'], result['s2']);
    expect(spots[2].meta['boardTextureTags'], result['s3']);
  });
}
