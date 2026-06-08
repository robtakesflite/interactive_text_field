import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../plugin.dart';
import '../plugin_context.dart';
import '../styled_range.dart';
import '../syntax/grammar.dart';
import 'syntax_highlight.dart' show SyntaxThemes;

/// How the [MarkdownPlugin] presents the source.
enum MarkdownMode {
  /// Show the markdown markers (e.g. `**`, `` ` ``, `#`, `> `) styled
  /// faintly so the user can still see what they typed and edit it.
  /// This is the editor experience (think: VS Code, Sublime).
  editor,

  /// Hide the markdown markers — the source is the same, but the markers
  /// collapse to zero-size so the rendered text reads like a finished
  /// document (think: Notion, Obsidian live preview).
  viewer,
}

/// Inline markdown styles. Block-level rendering (headers as bigger blocks,
/// list bullets, blockquote padding) is intentionally out of scope —
/// this is an editor plugin; it styles spans in place.
@immutable
class MarkdownStyle {
  const MarkdownStyle({
    this.bold,
    this.italic,
    this.boldItalic,
    this.strikethrough,
    this.inlineCode,
    this.link,
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.blockquote,
    this.bullet,
    this.delimiter,
    this.codeBlock,
    this.fenceMarker,
  });

  final TextStyle? bold;
  final TextStyle? italic;
  final TextStyle? boldItalic;
  final TextStyle? strikethrough;
  final TextStyle? inlineCode;
  final TextStyle? link;
  final TextStyle? h1;
  final TextStyle? h2;
  final TextStyle? h3;
  final TextStyle? h4;
  final TextStyle? h5;
  final TextStyle? h6;
  final TextStyle? blockquote;
  final TextStyle? bullet;

  /// Style applied to the markdown delimiters themselves (e.g. the
  /// surrounding `**` of bold) in [MarkdownMode.editor]. Defaults to a
  /// faint look so users can see the syntax without it distracting from
  /// the content. In [MarkdownMode.viewer], delimiters are forced
  /// invisible regardless of this style.
  final TextStyle? delimiter;

  /// Style for the body of a fenced code block (the content between the
  /// ``` markers). Usually a monospace family with a slightly tinted
  /// background.
  final TextStyle? codeBlock;

  /// Style for the ``` lines themselves. Like [delimiter], hidden in
  /// viewer mode.
  final TextStyle? fenceMarker;

  static const MarkdownStyle defaults = MarkdownStyle(
    bold: TextStyle(fontWeight: FontWeight.bold),
    italic: TextStyle(fontStyle: FontStyle.italic),
    boldItalic: TextStyle(
      fontWeight: FontWeight.bold,
      fontStyle: FontStyle.italic,
    ),
    strikethrough: TextStyle(decoration: TextDecoration.lineThrough),
    inlineCode: TextStyle(
      fontFamily: 'monospace',
      backgroundColor: Color(0x14000000),
      letterSpacing: 0,
    ),
    link: TextStyle(
      color: Color(0xFF1976D2),
      decoration: TextDecoration.underline,
    ),
    h1: TextStyle(fontWeight: FontWeight.w800, fontSize: 28),
    h2: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
    h3: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
    h4: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
    h5: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    h6: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
    blockquote: TextStyle(
      color: Color(0xFF6A737D),
      fontStyle: FontStyle.italic,
    ),
    bullet: TextStyle(
      color: Color(0xFF735C0F),
      fontWeight: FontWeight.w700,
    ),
    delimiter: TextStyle(color: Color(0xFFB0B0B0)),
    codeBlock: TextStyle(
      fontFamily: 'monospace',
      backgroundColor: Color(0x0A000000),
    ),
    fenceMarker: TextStyle(color: Color(0xFFB0B0B0)),
  );
}

/// Style that collapses text to zero — used in viewer mode to hide
/// markdown markers without removing them from the source.
const TextStyle _hidden = TextStyle(
  fontSize: 0.01,
  color: Color(0x00000000),
  height: 0.0,
  letterSpacing: -10,
);

/// Decorates inline markdown markers in the editor text, and optionally
/// syntax-highlights fenced code blocks (`` ```dart `` … `` ``` ``).
///
/// Two modes via [MarkdownMode]:
///   * `editor` — markers remain visible but dimmed.
///   * `viewer` — markers collapse to zero size; reads like rendered
///     markdown but the underlying text is unchanged.
///
/// Pass [syntaxTheme] / [grammarRegistry] to control how the inside of
/// fenced code blocks is colored.
class MarkdownPlugin extends InteractiveTextPlugin {
  MarkdownPlugin({
    this.style = MarkdownStyle.defaults,
    this.priority = 5,
    this.mode = MarkdownMode.editor,
    this.syntaxTheme = SyntaxThemes.githubLight,
    GrammarRegistry? grammarRegistry,
  }) : grammarRegistry = grammarRegistry ?? GrammarRegistry.defaults;

  final MarkdownStyle style;
  final int priority;
  final MarkdownMode mode;
  final SyntaxTheme syntaxTheme;
  final GrammarRegistry grammarRegistry;

  static final RegExp _fencedCode = RegExp(
    r'^```([a-zA-Z0-9_+-]*)\s*\n([\s\S]*?)(?:\n```|$)',
    multiLine: true,
  );
  static final RegExp _boldItalic = RegExp(r'\*\*\*([^*\n]+)\*\*\*');
  static final RegExp _bold =
      RegExp(r'\*\*([^*\n]+)\*\*|__([^_\n]+)__');
  static final RegExp _italic = RegExp(
    r'(?<![*\w])\*([^*\n]+)\*(?!\*)|(?<![_\w])_([^_\n]+)_(?!_)',
  );
  static final RegExp _strike = RegExp(r'~~([^~\n]+)~~');
  static final RegExp _code = RegExp(r'`([^`\n]+)`');
  static final RegExp _link = RegExp(r'\[([^\]\n]+)\]\(([^)\n]+)\)');
  static final RegExp _heading =
      RegExp(r'^(#{1,6})[ \t]+(.+)$', multiLine: true);
  static final RegExp _blockquote =
      RegExp(r'^>[ \t]?(.*)$', multiLine: true);
  static final RegExp _bullet = RegExp(
    r'^[ \t]*([-*+]|\d+\.)[ \t]+',
    multiLine: true,
  );
  static final RegExp _task = RegExp(
    r'^[ \t]*([-*+])[ \t]+(\[[ xX]\])[ \t]+',
    multiLine: true,
  );

  TextStyle get _delimiterStyle =>
      mode == MarkdownMode.viewer ? _hidden : (style.delimiter ?? _hidden);
  TextStyle get _fenceMarkerStyle =>
      mode == MarkdownMode.viewer ? _hidden : (style.fenceMarker ?? _hidden);

  @override
  DecorationResult decorate(DecorationContext ctx) {
    final text = ctx.text;
    if (text.isEmpty) return const DecorationResult.empty();

    final out = <StyledRange>[];
    final fencedRanges = <_FenceRange>[];

    void addDelim(int s, int e) {
      if (e <= s) return;
      out.add(StyledRange(
        start: s,
        end: e,
        style: _delimiterStyle,
        priority: priority + 50,
        data: 'delimiter',
      ));
    }

    void addRange(
      int s,
      int e,
      TextStyle? style, {
      String? data,
      int p = 0,
    }) {
      if (style == null) return;
      if (e <= s) return;
      out.add(StyledRange(
        start: s,
        end: e,
        style: style,
        priority: priority + p,
        data: data,
      ));
    }

    // 1) Fenced code blocks — strongest precedence; we collect their
    //    ranges so other markdown rules don't fire inside them.
    for (final m in _fencedCode.allMatches(text)) {
      final lang = m.group(1) ?? '';
      final fenceOpenStart = m.start;
      final fenceOpenEnd = m.start + 3 + lang.length;
      final bodyStart = text.indexOf('\n', fenceOpenStart) + 1;
      final bool closed =
          m.end - m.start >= 3 && text.substring(m.end - 3, m.end) == '```';
      int fenceCloseStart;
      int fenceCloseEnd;
      if (closed) {
        fenceCloseStart = m.end - 3;
        fenceCloseEnd = m.end;
      } else {
        fenceCloseStart = m.end;
        fenceCloseEnd = m.end;
      }
      // When closed, the `\n` immediately before the closing fence is a
      // separator, not body. But the regex's `(?:\n```|$)` allows the
      // close to match `$` directly (e.g. `"```\nbody```"` with no
      // trailing newline before the close fence) — in that case there is
      // no separator newline to exclude.
      final int bodyEnd;
      if (closed) {
        final hasSeparatorNewline = fenceCloseStart > bodyStart &&
            text.codeUnitAt(fenceCloseStart - 1) == 0x0A;
        bodyEnd = hasSeparatorNewline ? fenceCloseStart - 1 : fenceCloseStart;
      } else {
        bodyEnd = m.end;
      }

      addRange(
        bodyStart,
        bodyEnd > bodyStart ? bodyEnd : bodyStart,
        style.codeBlock,
        data: 'code_block',
        p: 5,
      );
      addRange(
        fenceOpenStart,
        fenceOpenEnd,
        _fenceMarkerStyle,
        data: 'fence_open',
        p: 4,
      );
      if (fenceCloseEnd > fenceCloseStart) {
        addRange(
          fenceCloseStart,
          fenceCloseEnd,
          _fenceMarkerStyle,
          data: 'fence_close',
          p: 4,
        );
      }
      // Hide the newline that separates the opening fence from the body
      // and the trailing language tag in viewer mode (already handled by
      // _fenceMarkerStyle covering fenceOpenStart..fenceOpenEnd).

      if (lang.isNotEmpty) {
        final grammar = grammarRegistry.lookup(lang);
        if (grammar != null && bodyEnd > bodyStart) {
          final body = text.substring(bodyStart, bodyEnd);
          out.addAll(
            tokenize(
              text: body,
              grammar: grammar,
              theme: syntaxTheme,
              offset: bodyStart,
              basePriority: priority + 8,
            ),
          );
        }
      }
      fencedRanges.add(_FenceRange(bodyStart, bodyEnd));
    }

    bool insideFence(int s, int e) {
      for (final fr in fencedRanges) {
        if (s >= fr.start && e <= fr.end) return true;
      }
      return false;
    }

    // 2) Block-level
    for (final m in _heading.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      final hashes = m.group(1)!;
      final level = hashes.length;
      final hStyle = switch (level) {
        1 => style.h1,
        2 => style.h2,
        3 => style.h3,
        4 => style.h4,
        5 => style.h5,
        _ => style.h6,
      };
      addRange(m.start, m.end, hStyle, data: 'h$level', p: 2);
      addDelim(m.start, m.start + hashes.length + 1);
    }

    for (final m in _blockquote.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      addRange(m.start, m.end, style.blockquote, data: 'blockquote', p: 1);
      addDelim(m.start, m.start + 1);
    }

    for (final m in _task.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      // Just style the markers; the rendered checkbox swap is the user's
      // responsibility (e.g. a separate widget overlay).
      addRange(m.start, m.end, style.bullet, data: 'task', p: 2);
      addDelim(m.start, m.end);
    }

    for (final m in _bullet.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      // Skip if this match is actually a task marker — _task handled it.
      final upToHere = text.substring(m.start, m.end);
      if (upToHere.contains('[')) continue;
      addRange(m.start, m.end, style.bullet, data: 'bullet', p: 1);
      // Delimiter coverage for the leading "- " / "1. "
      addDelim(m.start, m.end);
    }

    // 3) Inline
    for (final m in _boldItalic.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      addRange(m.start, m.end, style.boldItalic, data: 'bold_italic', p: 3);
      addDelim(m.start, m.start + 3);
      addDelim(m.end - 3, m.end);
    }
    for (final m in _bold.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      if (_overlapsRange(text, m, _boldItalic)) continue;
      addRange(m.start, m.end, style.bold, data: 'bold', p: 2);
      addDelim(m.start, m.start + 2);
      addDelim(m.end - 2, m.end);
    }
    for (final m in _italic.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      if (_overlapsRange(text, m, _bold)) continue;
      if (_overlapsRange(text, m, _boldItalic)) continue;
      addRange(m.start, m.end, style.italic, data: 'italic', p: 1);
      addDelim(m.start, m.start + 1);
      addDelim(m.end - 1, m.end);
    }
    for (final m in _strike.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      addRange(m.start, m.end, style.strikethrough, data: 'strike', p: 1);
      addDelim(m.start, m.start + 2);
      addDelim(m.end - 2, m.end);
    }
    for (final m in _code.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      addRange(m.start, m.end, style.inlineCode, data: 'code', p: 4);
      addDelim(m.start, m.start + 1);
      addDelim(m.end - 1, m.end);
    }
    for (final m in _link.allMatches(text)) {
      if (insideFence(m.start, m.end)) continue;
      final labelEnd = m.start + m.group(1)!.length + 2; // [label]
      addRange(
        m.start + 1,
        m.start + 1 + m.group(1)!.length,
        style.link,
        data: 'link',
        p: 2,
      );
      addDelim(m.start, m.start + 1);
      addDelim(labelEnd - 1, m.end);
    }

    return DecorationResult(out);
  }

  bool _overlapsRange(String text, Match a, RegExp other) {
    for (final b in other.allMatches(text)) {
      if (b.start <= a.start && b.end >= a.end) return true;
    }
    return false;
  }
}

class _FenceRange {
  const _FenceRange(this.start, this.end);
  final int start;
  final int end;
}
