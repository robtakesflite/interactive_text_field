import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../plugin.dart';
import '../plugin_context.dart';
import '../styled_range.dart';

/// Function that, given the current text, returns a [TextStyle] override
/// to apply globally. Return null for "no override".
typedef BaseStyleResolver = TextStyle? Function(String text);

/// Function that, given a pattern match, returns the [TextStyle] to apply
/// to that range. Return null to skip the match.
typedef MatchStyleResolver = TextStyle? Function(RegExpMatch match);

/// A pattern + style pair for [EffectsPlugin] pattern-triggered effects.
@immutable
class PatternEffect {
  const PatternEffect({
    required this.pattern,
    required this.style,
    this.priority = 0,
    this.label,
  });

  final RegExp pattern;
  final TextStyle style;
  final int priority;
  final String? label;
}

/// Live, content-driven text effects.
///
/// The [EffectsPlugin] composes two ideas:
///
/// 1. **Global base-style effects** — the entire field's [TextStyle]
///    transforms based on current text. Used for things like iMessage's
///    "big text" effect (short messages render larger), shouty all-caps
///    enlargement, or a mood theme that swaps colors based on content.
///    The [InteractiveTextField] animates transitions between styles, so
///    these effects look smooth as the user types.
///
/// 2. **Pattern-triggered range effects** — like [RegexHighlightPlugin],
///    but framed around presentation effects (e.g. a token grows on first
///    appearance, an emoji shifts colors). Plugins receive the [Match]
///    so the style can depend on the matched content.
///
/// Use the factories on [Effects] for common iMessage-style presets, or
/// build your own with [baseStyleResolver] / [effects].
class EffectsPlugin extends InteractiveTextPlugin {
  EffectsPlugin({
    this.baseStyleResolver,
    List<PatternEffect> effects = const [],
    this.priority = 4,
  }) : _effects = List.of(effects);

  /// Optional callback that returns a global style override for the field
  /// based on the current text content.
  final BaseStyleResolver? baseStyleResolver;

  final List<PatternEffect> _effects;
  final int priority;

  List<PatternEffect> get effects => List.unmodifiable(_effects);

  void addEffect(PatternEffect effect) {
    _effects.add(effect);
    if (isAttached) context.requestRebuild();
  }

  void removeEffect(PatternEffect effect) {
    if (_effects.remove(effect) && isAttached) context.requestRebuild();
  }

  void setEffects(List<PatternEffect> effects) {
    _effects
      ..clear()
      ..addAll(effects);
    if (isAttached) context.requestRebuild();
  }

  @override
  TextStyle? overrideBaseStyle(String text, TextStyle current) {
    return baseStyleResolver?.call(text);
  }

  @override
  DecorationResult decorate(DecorationContext ctx) {
    if (_effects.isEmpty || ctx.text.isEmpty) {
      return const DecorationResult.empty();
    }
    final out = <StyledRange>[];
    for (final e in _effects) {
      for (final m in e.pattern.allMatches(ctx.text)) {
        if (m.end <= m.start) continue;
        out.add(StyledRange(
          start: m.start,
          end: m.end,
          style: e.style,
          priority: priority + e.priority,
          data: e.label,
        ));
      }
    }
    return DecorationResult(out);
  }
}

/// Collection of ready-made effect presets.
class Effects {
  Effects._();

  /// iMessage-style: text grows for short messages, shrinks for long
  /// ones. Single-emoji messages get especially large. Color subtly
  /// warms up on short messages and cools on long ones to add character
  /// to the animation.
  ///
  /// Configure thresholds via [shortThreshold] and [mediumThreshold].
  static BaseStyleResolver iMessageScale({
    double shortFontSize = 34,
    double longFontSize = 16,
    double emojiFontSize = 72,
    int shortThreshold = 12,
    int mediumThreshold = 60,
    Color shortColor = const Color(0xFFE91E63),
    Color longColor = const Color(0xFF1F1F1F),
    double shortWeight = 800,
    double longWeight = 400,
    double shortLetterSpacing = 0.4,
    double longLetterSpacing = 0,
  }) {
    final emojiOnly = RegExp(
      r'^[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{27BF}\s]+$',
      unicode: true,
    );
    Color lerpColor(Color a, Color b, double t) =>
        Color.lerp(a, b, t.clamp(0.0, 1.0))!;
    return (text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) {
        return TextStyle(
          fontSize: shortFontSize,
          color: shortColor,
          fontWeight: _weight(shortWeight),
          letterSpacing: shortLetterSpacing,
        );
      }
      if (emojiOnly.hasMatch(trimmed)) {
        return TextStyle(
          fontSize: emojiFontSize,
          color: shortColor,
          fontWeight: _weight(shortWeight),
          letterSpacing: 0,
        );
      }
      final len = trimmed.length;
      double t;
      if (len <= shortThreshold) {
        t = 0;
      } else if (len >= mediumThreshold) {
        t = 1;
      } else {
        t = (len - shortThreshold) / (mediumThreshold - shortThreshold);
        // Ease — slightly cubic so the middle range is more dynamic.
        t = t * t * (3 - 2 * t);
      }
      return TextStyle(
        fontSize: shortFontSize + (longFontSize - shortFontSize) * t,
        color: lerpColor(shortColor, longColor, t),
        fontWeight:
            _weight(shortWeight + (longWeight - shortWeight) * t),
        letterSpacing:
            shortLetterSpacing + (longLetterSpacing - shortLetterSpacing) * t,
      );
    };
  }

  static FontWeight _weight(double v) {
    final clamped = v.clamp(100, 900).toDouble();
    final idx = ((clamped - 100) / 100).round().clamp(0, 8);
    return FontWeight.values[idx];
  }

  /// Highlights `**SHOUTING**` patterns (3+ uppercase letters) with a
  /// bold, scaled style.
  static PatternEffect shouting({
    TextStyle? style,
    int priority = 5,
  }) =>
      PatternEffect(
        pattern: RegExp(r'\b[A-Z]{3,}\b'),
        style: style ??
            const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
        priority: priority,
        label: 'shouting',
      );

  /// Tints emoji-like sequences slightly so they stand out from
  /// surrounding text.
  static PatternEffect emojiPop({
    TextStyle? style,
    int priority = 5,
  }) =>
      PatternEffect(
        pattern: RegExp(
          r'[\u{1F300}-\u{1F6FF}\u{1F900}-\u{1F9FF}\u{2600}-\u{27BF}]+',
          unicode: true,
        ),
        style: style ?? const TextStyle(fontSize: 22, height: 1.0),
        priority: priority,
        label: 'emoji',
      );

  /// Renders numbers in a slightly different color so quantities pop.
  static PatternEffect numbers({
    TextStyle? style,
    int priority = 3,
  }) =>
      PatternEffect(
        pattern: RegExp(r'\b\d+(?:\.\d+)?\b'),
        style: style ?? const TextStyle(color: Color(0xFF1976D2)),
        priority: priority,
        label: 'number',
      );
}
