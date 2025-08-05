import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/theory_mini_lesson_node.dart';
import '../theme/app_colors.dart';
import '../widgets/theory_lesson_context_overlay.dart';
import '../widgets/theory_path_map_toggle_button.dart';
import '../widgets/theory_lesson_feedback_bar.dart';
import '../widgets/theory_lesson_cluster_navigation_widget.dart';

/// Inline markdown syntax for ==highlight== spans.
class _HighlightSyntax extends md.InlineSyntax {
  _HighlightSyntax() : super(r'==(.*?)==');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final text = match.group(1)!;
    parser.addNode(md.Element.text('highlight', text));
    return true;
  }
}

/// Builder that renders highlighted markdown spans.
class _HighlightBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.yellow.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        element.textContent,
        style: preferredStyle,
      ),
    );
  }
}

/// Viewer for [TheoryMiniLessonNode] content with progress and actions.
class TheoryLessonViewerScreen extends StatelessWidget {
  final TheoryMiniLessonNode lesson;
  final int currentIndex;
  final int totalCount;
  final VoidCallback? onContinue;
  final VoidCallback? onReview;
  final VoidCallback? onAskQuestion;

  const TheoryLessonViewerScreen({
    super.key,
    required this.lesson,
    required this.currentIndex,
    required this.totalCount,
    this.onContinue,
    this.onReview,
    this.onAskQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    final scale = MediaQuery.textScaleFactorOf(context);
    final style = MarkdownStyleSheet.fromTheme(theme).copyWith(
      h1: theme.textTheme.headlineMedium?.copyWith(
        fontSize: 28 * scale,
        fontWeight: FontWeight.bold,
      ),
      h2: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 24 * scale,
        fontWeight: FontWeight.bold,
      ),
      h3: theme.textTheme.titleLarge?.copyWith(
        fontSize: 20 * scale,
        fontWeight: FontWeight.bold,
      ),
      code: const TextStyle(fontFamily: 'monospace'),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: StickyHeader(
                  header: Container(
                    color: AppColors.cardBackground,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lesson.resolvedTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimaryDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '$currentIndex/$totalCount',
                          style: const TextStyle(
                              color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                  content: Markdown(
                    data: lesson.resolvedContent,
                    styleSheet: style,
                    extensionSet: md.ExtensionSet.gitHubFlavored,
                    inlineSyntaxes: [_HighlightSyntax()],
                    builders: {'highlight': _HighlightBuilder()},
                  ),
                ),
              ),
              TheoryLessonClusterNavigationWidget(
                currentLessonId: lesson.id,
              ),
            ],
          ),
          TheoryLessonFeedbackBar(lessonId: lesson.id),
          SafeArea(
            child: Container(
              color: AppColors.cardBackground,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onContinue,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: accent),
                      child: const Text('Continue'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent),
                      ),
                      child: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onAskQuestion,
                    icon: const Icon(Icons.help_outline),
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
          TheoryLessonContextOverlay(lessonId: lesson.id),
          TheoryPathMapToggleButton(lesson: lesson),
        ],
      ),
    );
  }
}
