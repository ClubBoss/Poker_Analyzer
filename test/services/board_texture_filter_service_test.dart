import 'package:test/test.dart';
import 'package:poker_analyzer/services/board_texture_filter_service.dart';

void main() {
  const svc = BoardTextureFilterService();

  test('low paired board matches low and paired filters', () {
    final board = ['2h', '5c', '5d'];
    expect(svc.filter(board, ['low', 'paired']), true);
    expect(svc.filter(board, ['aceHigh']), false);
  });

  test('ace high board matches aceHigh filter only', () {
    final board = ['As', 'Kd', '3c'];
    expect(svc.filter(board, ['aceHigh']), true);
    expect(svc.filter(board, ['low']), false);
  });
}
