import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

DecorationContext _ctx(String text) => DecorationContext(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
      hasFocus: false,
    );

bool _hasData(DecorationResult r, String label) =>
    r.ranges.any((x) => x.data == label);

void main() {
  group('MarkdownPlugin', () {
    final plugin = MarkdownPlugin();

    test('bold', () {
      expect(_hasData(plugin.decorate(_ctx('a **bold** b')), 'bold'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('a __also bold__ b')), 'bold'), isTrue);
    });

    test('italic', () {
      expect(_hasData(plugin.decorate(_ctx('a *italic* b')), 'italic'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('a _italic_ b')), 'italic'), isTrue);
    });

    test('bold-italic', () {
      expect(_hasData(plugin.decorate(_ctx('a ***bold italic*** b')), 'bold_italic'),
          isTrue);
    });

    test('strikethrough', () {
      expect(_hasData(plugin.decorate(_ctx('a ~~strike~~ b')), 'strike'), isTrue);
    });

    test('inline code', () {
      expect(_hasData(plugin.decorate(_ctx('a `code` b')), 'code'), isTrue);
    });

    test('link', () {
      expect(_hasData(plugin.decorate(_ctx('[label](https://x.io)')), 'link'),
          isTrue);
    });

    test('headings', () {
      expect(_hasData(plugin.decorate(_ctx('# title')), 'h1'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('## subtitle')), 'h2'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('### sub')), 'h3'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('###### tiny')), 'h6'), isTrue);
    });

    test('blockquote', () {
      expect(_hasData(plugin.decorate(_ctx('> quote here')), 'blockquote'),
          isTrue);
    });

    test('bullet list', () {
      expect(_hasData(plugin.decorate(_ctx('- item')), 'bullet'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('* item')), 'bullet'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('+ item')), 'bullet'), isTrue);
      expect(_hasData(plugin.decorate(_ctx('1. item')), 'bullet'), isTrue);
    });

    test('empty text', () {
      expect(plugin.decorate(_ctx('')).ranges, isEmpty);
    });

    test('unclosed fenced code block covers body to end of text', () {
      // Regression: previously, an unclosed fence dropped the last char
      // of the body because the close-detection branch always subtracted 1.
      const text = '```dart\nlet x = 1';
      final result = plugin.decorate(_ctx(text));
      final codeBlock =
          result.ranges.firstWhere((r) => r.data == 'code_block');
      expect(codeBlock.start, 8); // after "```dart\n"
      expect(codeBlock.end, text.length); // through last char "1"
    });

    test('closed fenced code block excludes the trailing newline + fence',
        () {
      const text = '```\nbody\n```';
      final result = plugin.decorate(_ctx(text));
      final codeBlock =
          result.ranges.firstWhere((r) => r.data == 'code_block');
      expect(text.substring(codeBlock.start, codeBlock.end), 'body');
    });

    test('closed fenced code block with no separator newline keeps full body',
        () {
      // Regression: `m.end - 1` was subtracted unconditionally, which
      // dropped the last body char when the close fence butted right up
      // against the body (no separator `\n`).
      const text = '```\nbody```';
      final result = plugin.decorate(_ctx(text));
      final codeBlock =
          result.ranges.firstWhere((r) => r.data == 'code_block');
      expect(text.substring(codeBlock.start, codeBlock.end), 'body');
    });

    test('viewer mode hides delimiters via near-zero font sizing', () {
      final viewer = MarkdownPlugin(mode: MarkdownMode.viewer);
      final ranges = viewer.decorate(_ctx('**bold**')).ranges;
      final delim =
          ranges.where((r) => r.data == 'delimiter').toList();
      expect(delim, isNotEmpty);
      for (final r in delim) {
        // viewer-mode delimiter style: collapsed to zero pixels.
        expect(r.style.fontSize, lessThan(1));
      }
    });

    test('fenced code block with language tag emits syntax tokens', () {
      // `class` is a Dart keyword, `Foo` is matched as a type, `1` as
      // a number — verifies the fenced body is run through the Dart
      // grammar registry.
      const src = '```dart\nclass Foo { int x = 1; }\n```';
      final ranges = plugin.decorate(_ctx(src)).ranges;
      final tokens = ranges
          .map((r) => r.data)
          .where((d) =>
              d is String &&
              d != 'code_block' &&
              d != 'fence_open' &&
              d != 'fence_close' &&
              d != 'delimiter')
          .toSet();
      expect(tokens, contains('keyword'));
      expect(tokens, contains('number'));
    });
  });
}
