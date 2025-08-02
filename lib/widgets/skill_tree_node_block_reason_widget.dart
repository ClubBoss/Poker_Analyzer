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

  SkillTreeNodeBlockReasonWidget({
    super.key,
    required this.nodeId,
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
                  prereqTitles: [
                    for (final id in link.prerequisites) _titleForNode(id),
                  ],
                  hint: link.hint,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DependencyItem extends StatelessWidget {
  final String title;
  final List<String> prereqTitles;
  final String hint;

  const _DependencyItem({
    required this.title,
    required this.prereqTitles,
    required this.hint,
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
        if (prereqTitles.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < prereqTitles.length; i++) ...[
                  Chip(
                    label: Text(
                      prereqTitles[i],
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (i != prereqTitles.length - 1)
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

