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
  });
}
