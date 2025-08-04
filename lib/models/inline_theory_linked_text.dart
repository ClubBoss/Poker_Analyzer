import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Represents a piece of text that may be plain or linked.
class InlineTextChunk {
  final String text;
  final VoidCallback? onTap;

  const InlineTextChunk({required this.text, this.onTap});

  bool get isLink => onTap != null;
}

/// A sequence of [InlineTextChunk]s that can render as [RichText].
class InlineTheoryLinkedText {
  final List<InlineTextChunk> chunks;

  const InlineTheoryLinkedText(this.chunks);

  /// Builds a [RichText] widget representing this linked text.
  RichText toRichText({TextStyle? style, TextStyle? linkStyle}) {
    final defaultLinkStyle = linkStyle ?? const TextStyle(color: Colors.blue);
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          for (final c in chunks)
            c.isLink
                ? TextSpan(
                    text: c.text,
                    style: defaultLinkStyle,
                    recognizer: TapGestureRecognizer()..onTap = c.onTap,
                  )
                : TextSpan(text: c.text),
        ],
      ),
    );
  }
}
