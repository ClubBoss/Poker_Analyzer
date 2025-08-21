import '../models/learning_path_node.dart';
import 'mistake_booster_path_node_decorator.dart';

/// Renders learning path nodes applying various decorators before use.
class LearningPathRenderer {
  final MistakeBoosterPathNodeDecorator boosterDecorator;

  const LearningPathRenderer({
    MistakeBoosterPathNodeDecorator? boosterDecorator,
  }) : boosterDecorator =
            boosterDecorator ?? const MistakeBoosterPathNodeDecorator();

  /// Applies decorators to [nodes] and returns the updated list.
  Future<List<LearningPathNode>> render(List<LearningPathNode> nodes) async {
    final decorated = await boosterDecorator.decorate(nodes);
    return decorated;
  }
}
