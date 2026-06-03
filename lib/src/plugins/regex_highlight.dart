import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../plugin.dart';
import '../plugin_context.dart';
import '../styled_range.dart';

/// Specifies how to style matches of a regex pattern.
@immutable
class RegexHighlightRule {
  const RegexHighlightRule({
    required this.pattern,
    required this.style,
    this.priority = 0,
    this.recognizerKey,
    this.label,
  });

  final RegExp pattern;
  final TextStyle style;

  /// Higher priority overrides lower priority where ranges overlap.
  final int priority;

  /// Opaque key forwarded to the controller's recognizer factory, useful
  /// for attaching gesture handlers (e.g. tappable URLs).
  final Object? recognizerKey;

  /// Optional human-readable label, useful for debugging.
  final String? label;
}

/// Decorates text with [TextStyle]s based on regular-expression matches.
///
/// Use cases: link detection, emoji shading, hashtags, phone-number
/// coloring, custom token shading.
///
/// Rules are evaluated independently. The controller's merger resolves
/// overlaps by priority.
///
/// Only the entire match is styled — sub-group offsets aren't reliably
/// exposed by Dart's `Match` API. Use lookaround anchors if you need to
/// match more text than you style.
class RegexHighlightPlugin extends InteractiveTextPlugin {
  RegexHighlightPlugin({List<RegexHighlightRule> rules = const []})
      : _rules = List.of(rules);

  final List<RegexHighlightRule> _rules;

  List<RegexHighlightRule> get rules => List.unmodifiable(_rules);

  void addRule(RegexHighlightRule rule) {
    _rules.add(rule);
    if (isAttached) context.requestRebuild();
  }

  void removeRule(RegexHighlightRule rule) {
    if (_rules.remove(rule) && isAttached) context.requestRebuild();
  }

  void setRules(List<RegexHighlightRule> rules) {
    _rules
      ..clear()
      ..addAll(rules);
    if (isAttached) context.requestRebuild();
  }

  @override
  DecorationResult decorate(DecorationContext ctx) {
    if (_rules.isEmpty || ctx.text.isEmpty) {
      return const DecorationResult.empty();
    }
    final out = <StyledRange>[];
    for (final rule in _rules) {
      for (final m in rule.pattern.allMatches(ctx.text)) {
        if (m.end <= m.start) continue;
        out.add(
          StyledRange(
            start: m.start,
            end: m.end,
            style: rule.style,
            priority: rule.priority,
            recognizerKey: rule.recognizerKey,
            data: rule.label,
          ),
        );
      }
    }
    return DecorationResult(out);
  }
}

/// Built-in common rules. Exposed as static factories so users can either
/// drop them in directly or fork them.
class CommonRegexRules {
  CommonRegexRules._();

  static RegexHighlightRule url({TextStyle? style, int priority = 10}) {
    return RegexHighlightRule(
      pattern: RegExp(
        r'\b((?:https?|ftp)://[^\s<>"]+|www\.[^\s<>"]+)',
        caseSensitive: false,
      ),
      style: style ??
          const TextStyle(
            color: Color(0xFF1976D2),
            decoration: TextDecoration.underline,
          ),
      priority: priority,
      recognizerKey: 'url',
      label: 'url',
    );
  }

  static RegexHighlightRule email({TextStyle? style, int priority = 10}) {
    return RegexHighlightRule(
      pattern: RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.-]+\b'),
      style: style ?? const TextStyle(color: Color(0xFF388E3C)),
      priority: priority,
      recognizerKey: 'email',
      label: 'email',
    );
  }

  static RegexHighlightRule hashtag({TextStyle? style, int priority = 5}) {
    return RegexHighlightRule(
      pattern: RegExp(r'(?<=^|\s)#[A-Za-z0-9_]+'),
      style: style ??
          const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.w600),
      priority: priority,
      recognizerKey: 'hashtag',
      label: 'hashtag',
    );
  }

  static RegexHighlightRule mention({TextStyle? style, int priority = 5}) {
    return RegexHighlightRule(
      pattern: RegExp(r'(?<=^|\s)@[A-Za-z0-9_]+'),
      style: style ??
          const TextStyle(color: Color(0xFF7B1FA2), fontWeight: FontWeight.w600),
      priority: priority,
      recognizerKey: 'mention',
      label: 'mention',
    );
  }
}
