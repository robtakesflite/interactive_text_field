import 'dart:async';
import 'dart:math' as math;

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

/// Continuous, paint-only oscillation applied to a matched range after
/// its appear-in animation finishes.
///
/// Only paint-time properties are cycled (color, shadow opacity) so the
/// pulse never re-flows the line. Animating layout-affecting properties
/// here (`fontSize`, `fontWeight`, `letterSpacing`) would visibly shift
/// the surrounding text on every frame — exactly the "whole sentence is
/// animating" feel you don't want.
@immutable
class PulseEffect {
  const PulseEffect({
    this.duration = const Duration(milliseconds: 1400),
    this.colorMin,
    this.colorMax,
    this.shadowOpacityMin,
    this.shadowOpacityMax,
  });

  /// One full breath (min → max → min).
  final Duration duration;

  /// Cycle the matched style's `color` between these endpoints. If either
  /// is null, color isn't pulsed.
  final Color? colorMin;
  final Color? colorMax;

  /// Cycle the alpha of every entry in the matched style's `shadows`
  /// between these endpoints (0.0..1.0). If either is null, shadows
  /// aren't pulsed.
  final double? shadowOpacityMin;
  final double? shadowOpacityMax;
}

/// A pattern + style pair for [EffectsPlugin] pattern-triggered effects.
@immutable
class PatternEffect {
  const PatternEffect({
    required this.pattern,
    required this.style,
    this.priority = 0,
    this.label,
    this.appearDuration = const Duration(milliseconds: 240),
    this.pulse,
  });

  final RegExp pattern;

  /// The fully-resolved style applied to matched ranges. To prevent the
  /// "whole sentence wiggles" effect, prefer differentiating with `color`,
  /// `decoration`, and `shadows` (paint-only) — `fontSize`,
  /// `fontWeight`, and `letterSpacing` here cause a one-time layout
  /// shift the moment the range first matches.
  final TextStyle style;

  final int priority;
  final String? label;

  /// How long a newly-matched range takes to animate (paint-only fade-in
  /// of color alpha + shadow) from neutral to [style]. Set
  /// [Duration.zero] for instant.
  final Duration appearDuration;

  /// If non-null, the matched range continuously pulses (paint-only)
  /// after appearing.
  final PulseEffect? pulse;
}

/// Live, content-driven text effects.
///
/// Two layers compose here:
///
/// 1. **Global base-style effects** — an entire field's [TextStyle] morphs
///    based on the current text via [baseStyleResolver]. Animated by the
///    field itself ([InteractiveTextField.baseStyleAnimationDuration]).
///
/// 2. **Per-range pattern effects** — each [PatternEffect] styles matched
///    ranges and can animate them. Animations are **paint-only**: color
///    alpha fades in on appearance; color and shadow opacity cycle during
///    pulse. Layout-affecting properties (`fontSize`, `fontWeight`,
///    `letterSpacing`) on the matched style apply *immediately* at match
///    time — they never animate, so the surrounding text never shifts.
///
/// While any range is mid-animation (appearing or pulsing) the plugin
/// schedules itself for the next frame, so animation continues without
/// the user typing. When everything settles, ticking stops.
class EffectsPlugin extends InteractiveTextPlugin {
  EffectsPlugin({
    this.baseStyleResolver,
    List<PatternEffect> effects = const [],
    this.priority = 4,
    this.tickInterval = const Duration(milliseconds: 16),
  }) : _effects = List.of(effects);

  /// Optional callback that returns a global style override for the field
  /// based on the current text content.
  final BaseStyleResolver? baseStyleResolver;

  /// Minimum time between animation frames while ranges are in motion.
  /// 16 ms ≈ 60 fps.
  final Duration tickInterval;

  final List<PatternEffect> _effects;
  final int priority;

  /// First time each currently-active range was observed, keyed by
  /// `<label>#<occurrence>@<matchedText>`. Used to compute appear-in
  /// progress and pulse phase.
  final Map<String, DateTime> _firstSeen = <String, DateTime>{};
  Timer? _tick;

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
    final now = DateTime.now();
    final out = <StyledRange>[];
    final liveKeys = <String>{};
    bool needsTick = false;

    for (final e in _effects) {
      int occurrence = 0;
      for (final m in e.pattern.allMatches(ctx.text)) {
        if (m.end <= m.start) continue;
        final matchText = ctx.text.substring(m.start, m.end);
        final key = '${e.label ?? '_'}#${occurrence++}@$matchText';
        liveKeys.add(key);
        final firstSeen = _firstSeen.putIfAbsent(key, () => now);
        final elapsedMs = now.difference(firstSeen).inMilliseconds;

        final appearMs = e.appearDuration.inMilliseconds;
        TextStyle style;
        if (appearMs > 0 && elapsedMs < appearMs) {
          final raw = (elapsedMs / appearMs).clamp(0.0, 1.0);
          style = _interpolateAppearance(e.style, _easeOutCubic(raw));
          needsTick = true;
        } else if (e.pulse != null && _pulseIsActive(e.pulse!)) {
          final pulse = e.pulse!;
          final pulseMs = pulse.duration.inMilliseconds;
          final sinceAppear = elapsedMs - appearMs;
          final phase = pulseMs <= 0 ? 0.0 : (sinceAppear % pulseMs) / pulseMs;
          // 0..1..0 via cosine.
          final wave = (1 - math.cos(2 * math.pi * phase)) / 2;
          style = _applyPulse(e.style, pulse, wave);
          needsTick = true;
        } else {
          style = e.style;
        }

        out.add(StyledRange(
          start: m.start,
          end: m.end,
          style: style,
          priority: priority + e.priority,
          data: e.label,
        ));
      }
    }

    _firstSeen.removeWhere((k, _) => !liveKeys.contains(k));

    if (needsTick) {
      _scheduleTick();
    } else {
      _tick?.cancel();
      _tick = null;
    }

    return DecorationResult(out);
  }

  void _scheduleTick() {
    if (_tick != null) return;
    if (!isAttached) return;
    _tick = Timer(tickInterval, () {
      _tick = null;
      if (isAttached) context.requestRebuild();
    });
  }

  /// Paint-only appearance interpolation: only fade in `color` alpha and
  /// scale up shadow alpha/blur/offset. Layout-affecting properties
  /// (`fontSize`, `fontWeight`, `letterSpacing`) snap in at t=0 to avoid
  /// reflowing the surrounding text.
  TextStyle _interpolateAppearance(TextStyle full, double t) {
    Color? color = full.color;
    if (color != null && t < 1.0) {
      // Lerp opacity from 0.4×base → 1.0×base. Starting at 0 would make
      // the word invisible on its first frame (the matched-range color
      // override completely replaces the base color in the span merger).
      // ignore: deprecated_member_use
      final baseAlpha = color.opacity;
      final scaled = 0.4 + 0.6 * t;
      // ignore: deprecated_member_use
      color = color.withOpacity((baseAlpha * scaled).clamp(0.0, 1.0));
    }

    List<Shadow>? shadows = full.shadows;
    if (shadows != null && shadows.isNotEmpty && t < 1.0) {
      shadows = [
        for (final s in shadows)
          Shadow(
            // ignore: deprecated_member_use
            color: s.color.withOpacity(
              // ignore: deprecated_member_use
              (s.color.opacity * t).clamp(0.0, 1.0),
            ),
            offset: Offset(s.offset.dx * t, s.offset.dy * t),
            blurRadius: s.blurRadius * t,
          ),
      ];
    }

    return full.copyWith(color: color, shadows: shadows);
  }

  /// Apply a single pulse sample. Only paint-time properties are touched.
  TextStyle _applyPulse(TextStyle base, PulseEffect pulse, double wave) {
    Color? color = base.color;
    if (pulse.colorMin != null && pulse.colorMax != null) {
      color = Color.lerp(pulse.colorMin, pulse.colorMax, wave);
    }

    List<Shadow>? shadows = base.shadows;
    if (shadows != null &&
        pulse.shadowOpacityMin != null &&
        pulse.shadowOpacityMax != null) {
      final opacity = (pulse.shadowOpacityMin! +
              (pulse.shadowOpacityMax! - pulse.shadowOpacityMin!) * wave)
          .clamp(0.0, 1.0);
      shadows = [
        for (final s in shadows)
          Shadow(
            // ignore: deprecated_member_use
            color: s.color.withOpacity(opacity),
            offset: s.offset,
            blurRadius: s.blurRadius,
          ),
      ];
    }

    return base.copyWith(color: color, shadows: shadows);
  }

  static bool _pulseIsActive(PulseEffect p) {
    final colorActive = p.colorMin != null && p.colorMax != null;
    final shadowActive =
        p.shadowOpacityMin != null && p.shadowOpacityMax != null;
    return colorActive || shadowActive;
  }

  static double _easeOutCubic(double t) {
    final p = t - 1.0;
    return p * p * p + 1.0;
  }

  @override
  void onDetach() {
    _tick?.cancel();
    _tick = null;
    _firstSeen.clear();
    super.onDetach();
  }
}

/// Collection of ready-made effect presets.
class Effects {
  Effects._();

  /// iMessage-style: text grows for short messages, shrinks for long
  /// ones. Single-emoji messages get especially large.
  ///
  /// The resolver returns one of four discrete tiers (huge / large /
  /// medium / normal) so each crossing produces a clearly visible jump
  /// that the field smoothly animates between. Smooth per-character
  /// interpolation reads as "static" to the eye; stepped tiers don't.
  ///
  /// Tiers (by trimmed character count):
  ///  * `0..=hugeMax`   → [hugeFontSize], [hugeColor] / [hugeWeight].
  ///  * `..=largeMax`   → [largeFontSize].
  ///  * `..=mediumMax`  → [mediumFontSize].
  ///  * `> mediumMax`   → [longFontSize], [longColor] / [longWeight].
  ///
  /// Pure-emoji content gets [emojiFontSize] regardless of length.
  static BaseStyleResolver iMessageScale({
    double hugeFontSize = 44,
    double largeFontSize = 32,
    double mediumFontSize = 22,
    double longFontSize = 16,
    double emojiFontSize = 72,
    int hugeMax = 3,
    int largeMax = 10,
    int mediumMax = 30,
    Color hugeColor = const Color(0xFFE91E63),
    Color longColor = const Color(0xFF1F1F1F),
    double hugeWeight = 800,
    double longWeight = 400,
    double hugeLetterSpacing = 0.4,
    double longLetterSpacing = 0,
  }) {
    final emojiOnly = RegExp(
      r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\s]+$',
      unicode: true,
    );
    Color lerpColor(Color a, Color b, double t) =>
        Color.lerp(a, b, t.clamp(0.0, 1.0))!;
    FontWeight lerpWeight(double a, double b, double t) =>
        _weight(a + (b - a) * t.clamp(0.0, 1.0));

    TextStyle tier(double size, double t) => TextStyle(
          fontSize: size,
          color: lerpColor(hugeColor, longColor, t),
          fontWeight: lerpWeight(hugeWeight, longWeight, t),
          letterSpacing:
              hugeLetterSpacing + (longLetterSpacing - hugeLetterSpacing) * t,
        );

    return (text) {
      final trimmed = text.trim();
      if (trimmed.isNotEmpty && emojiOnly.hasMatch(trimmed)) {
        return TextStyle(
          fontSize: emojiFontSize,
          color: hugeColor,
          fontWeight: _weight(hugeWeight),
          letterSpacing: 0,
        );
      }
      final len = trimmed.length;
      if (len <= hugeMax) return tier(hugeFontSize, 0.0);
      if (len <= largeMax) return tier(largeFontSize, 0.33);
      if (len <= mediumMax) return tier(mediumFontSize, 0.66);
      return tier(longFontSize, 1.0);
    };
  }

  static FontWeight _weight(double v) {
    final clamped = v.clamp(100, 900).toDouble();
    final idx = ((clamped - 100) / 100).round().clamp(0, 8);
    return FontWeight.values[idx];
  }

  /// SHOUTING (3+ uppercase letters) becomes bold and red, then
  /// continuously pulses red ↔ coral. Paint-only — surrounding text
  /// never shifts.
  static PatternEffect shouting({
    TextStyle? style,
    int priority = 5,
    Duration appearDuration = const Duration(milliseconds: 280),
    PulseEffect? pulse = const PulseEffect(
      duration: Duration(milliseconds: 1400),
      colorMin: Color(0xFFD32F2F),
      colorMax: Color(0xFFFF6E40),
    ),
  }) =>
      PatternEffect(
        pattern: RegExp(r'\b[A-Z]{3,}\b'),
        style: style ??
            const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFFD32F2F),
            ),
        priority: priority,
        label: 'shouting',
        appearDuration: appearDuration,
        pulse: pulse,
      );

  /// Inline emoji get a soft shadow that fades in, then continuously
  /// breathes (shadow opacity 0.25 ↔ 0.75). Paint-only.
  static PatternEffect emojiPop({
    TextStyle? style,
    int priority = 5,
    Duration appearDuration = const Duration(milliseconds: 220),
    PulseEffect? pulse = const PulseEffect(
      duration: Duration(milliseconds: 1600),
      shadowOpacityMin: 0.25,
      shadowOpacityMax: 0.75,
    ),
  }) =>
      PatternEffect(
        pattern: RegExp(
          r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]+',
          unicode: true,
        ),
        style: style ??
            const TextStyle(
              shadows: [
                Shadow(
                  color: Color(0xFF000000),
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ],
            ),
        priority: priority,
        label: 'emoji',
        appearDuration: appearDuration,
        pulse: pulse,
      );

  /// Numbers fade in tinted bold blue; no pulse by default.
  static PatternEffect numbers({
    TextStyle? style,
    int priority = 3,
    Duration appearDuration = const Duration(milliseconds: 200),
    PulseEffect? pulse,
  }) =>
      PatternEffect(
        pattern: RegExp(r'\b\d+(?:\.\d+)?\b'),
        style: style ??
            const TextStyle(
              color: Color(0xFF1976D2),
              fontWeight: FontWeight.w700,
            ),
        priority: priority,
        label: 'number',
        appearDuration: appearDuration,
        pulse: pulse,
      );
}
