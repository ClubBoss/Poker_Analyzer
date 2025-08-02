import 'package:flutter/material.dart';

import '../models/skill_tree_dependency_link.dart';
import '../services/skill_tree_dependency_link_service.dart';
import '../services/skill_tree_library_service.dart';

/// Widget that shows why a skill tree node is blocked.
///
/// It lists the prerequisite chain and unlock hint for each locked
/// dependency returned by [SkillTreeDependencyLinkService]. The widget is
/// designed to fit into small spaces such as modals or tooltips.
class SkillTreeNodeBlockReasonWidget extends StatelessWidget {
  final String nodeId;
  final SkillTreeDependencyLinkService _linkService;
  final SkillTreeLibraryService _library;
  final void Function(String nodeId)? onJumpToNode;

  SkillTreeNodeBlockReasonWidget({
    super.key,
    required this.nodeId,
    this.onJumpToNode,
    SkillTreeDependencyLinkService? linkService,
    SkillTreeLibraryService? library,
  })  : _linkService = linkService ?? SkillTreeDependencyLinkService(),
        _library = library ?? SkillTreeLibraryService.instance;

  String _titleForNode(String id) {
    for (final n in _library.getAllNodes()) {
      if (n.id == id) return n.title;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SkillTreeDependencyLink>>(
      future: _linkService.getDependencies(nodeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final deps = snapshot.data!;
        if (deps.isEmpty) {
          return const Text(
            'No unlock requirements available',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final link in deps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _DependencyItem(
                  title: _titleForNode(link.nodeId),
                  prereqs: [
                    for (final id in link.prerequisites)
                      _Prereq(id: id, title: _titleForNode(id)),
                  ],
                  hint: link.hint,
                  onJumpToNode: onJumpToNode,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Prereq {
  final String id;
  final String title;

  _Prereq({required this.id, required this.title});
}

class _DependencyItem extends StatelessWidget {
  final String title;
  final List<_Prereq> prereqs;
  final String hint;
  final void Function(String nodeId)? onJumpToNode;

  const _DependencyItem({
    required this.title,
    required this.prereqs,
    required this.hint,
    this.onJumpToNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        if (prereqs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < prereqs.length; i++) ...[
                  GestureDetector(
                    onTap: onJumpToNode != null
                        ? () => onJumpToNode!(prereqs[i].id)
                        : null,
                    child: Chip(
                      label: Text(
                        prereqs[i].title,
                        style: const TextStyle(fontSize: 12),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  if (i != prereqs.length - 1)
                    const Icon(Icons.arrow_right,
                        size: 14, color: Colors.grey),
                ],
              ],
            ),
          ),
        if (hint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

