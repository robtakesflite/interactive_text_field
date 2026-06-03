import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

import 'styled_range.dart';

/// Flattens an arbitrary set of (possibly overlapping) [StyledRange]s into
/// a non-overlapping sequence of [TextSpan]s covering [text].
///
/// Algorithm:
///   1. Collect every range boundary (start + end) as a "cut point".
///   2. Sort and de-duplicate cut points.
///   3. For each [start, end) interval between consecutive cut points,
///      find every input range that covers it; merge their styles in
///      ascending priority order (higher priority wins).
///   4. Emit one [TextSpan] per merged interval, plus literal plain spans
///      for the gaps.
///
/// This is O(n log n + n·k) where n = number of cut points and k = number
/// of overlapping ranges at any single point — fine for editor-sized text
/// (a few thousand chars, dozens of plugins).
List<TextSpan> mergeRangesToSpans({
  required String text,
  required List<StyledRange> ranges,
  TextStyle? baseStyle,
  GestureRecognizer? Function(StyledRange range)? recognizerFor,
}) {
  if (text.isEmpty) return const <TextSpan>[];

  final length = text.length;
  final clipped = <StyledRange>[];
  for (final r in ranges) {
    final s = r.start.clamp(0, length);
    final e = r.end.clamp(0, length);
    if (e > s) {
      clipped.add(r.copyWith(start: s, end: e));
    }
  }
  if (clipped.isEmpty) {
    return <TextSpan>[TextSpan(text: text, style: baseStyle)];
  }

  final cuts = <int>{0, length};
  for (final r in clipped) {
    cuts.add(r.start);
    cuts.add(r.end);
  }
  final sortedCuts = cuts.toList()..sort();

  final result = <TextSpan>[];
  for (int i = 0; i < sortedCuts.length - 1; i++) {
    final segStart = sortedCuts[i];
    final segEnd = sortedCuts[i + 1];
    if (segStart == segEnd) continue;

    final covering = <StyledRange>[];
    for (final r in clipped) {
      if (r.start <= segStart && r.end >= segEnd) covering.add(r);
    }
    covering.sort((a, b) => a.priority.compareTo(b.priority));

    TextStyle style = baseStyle ?? const TextStyle();
    GestureRecognizer? recognizer;
    for (final r in covering) {
      style = style.merge(r.style);
      if (recognizerFor != null) {
        final gr = recognizerFor(r);
        if (gr != null) recognizer = gr;
      }
    }

    result.add(
      TextSpan(
        text: text.substring(segStart, segEnd),
        style: style,
        recognizer: recognizer,
      ),
    );
  }
  return _coalesce(result);
}

List<TextSpan> _coalesce(List<TextSpan> input) {
  if (input.length < 2) return input;
  final out = <TextSpan>[input.first];
  for (int i = 1; i < input.length; i++) {
    final prev = out.last;
    final cur = input[i];
    if (prev.recognizer == null &&
        cur.recognizer == null &&
        prev.style == cur.style) {
      out[out.length - 1] = TextSpan(
        text: (prev.text ?? '') + (cur.text ?? ''),
        style: prev.style,
      );
    } else {
      out.add(cur);
    }
  }
  return out;
}
