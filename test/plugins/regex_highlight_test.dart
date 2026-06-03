import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

DecorationContext _ctx(String text) => DecorationContext(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
      composing: TextRange.empty,
      hasFocus: false,
    );

void main() {
  group('RegexHighlightPlugin', () {
    test('emits ranges for matches', () {
      final plugin = RegexHighlightPlugin(rules: [
        RegexHighlightRule(
          pattern: RegExp(r'\bTODO\b'),
          style: const TextStyle(color: Color(0xFFFF0000)),
        ),
      ]);
      final result = plugin.decorate(_ctx('TODO this then TODO that'));
      expect(result.ranges, hasLength(2));
      expect(result.ranges.first.start, 0);
      expect(result.ranges.first.end, 4);
      expect(result.ranges.last.start, 15);
    });

    test('returns empty result with no rules', () {
      final plugin = RegexHighlightPlugin();
      expect(plugin.decorate(_ctx('hello')).ranges, isEmpty);
    });

    test('returns empty for empty text', () {
      final plugin = RegexHighlightPlugin(rules: [
        RegexHighlightRule(
          pattern: RegExp(r'\bTODO\b'),
          style: const TextStyle(),
        ),
      ]);
      expect(plugin.decorate(_ctx('')).ranges, isEmpty);
    });

    test('CommonRegexRules.url matches http/https/www', () {
      final plugin =
          RegexHighlightPlugin(rules: [CommonRegexRules.url()]);
      final result = plugin.decorate(_ctx(
        'see https://a.com or http://b.org or www.c.net',
      ));
      expect(result.ranges, hasLength(3));
    });

    test('CommonRegexRules.email matches addresses', () {
      final plugin =
          RegexHighlightPlugin(rules: [CommonRegexRules.email()]);
      final result = plugin.decorate(_ctx('contact me@example.com today'));
      expect(result.ranges, hasLength(1));
    });

    test('CommonRegexRules.hashtag matches after whitespace', () {
      final plugin =
          RegexHighlightPlugin(rules: [CommonRegexRules.hashtag()]);
      final result = plugin.decorate(_ctx('#first and #second #third'));
      expect(result.ranges, hasLength(3));
    });

    test('CommonRegexRules.mention matches @handles', () {
      final plugin =
          RegexHighlightPlugin(rules: [CommonRegexRules.mention()]);
      final result = plugin.decorate(_ctx('cc @rob and @alex'));
      expect(result.ranges, hasLength(2));
    });

    test('rule priority is preserved on the StyledRange', () {
      final plugin = RegexHighlightPlugin(rules: [
        RegexHighlightRule(
          pattern: RegExp(r'foo'),
          style: const TextStyle(),
          priority: 99,
        ),
      ]);
      final r = plugin.decorate(_ctx('foo bar')).ranges.first;
      expect(r.priority, 99);
    });

    test('setRules replaces the rule list', () {
      final plugin = RegexHighlightPlugin(rules: [
        RegexHighlightRule(
          pattern: RegExp(r'a'),
          style: const TextStyle(),
        ),
      ]);
      plugin.setRules([
        RegexHighlightRule(
          pattern: RegExp(r'b'),
          style: const TextStyle(),
        ),
      ]);
      expect(plugin.decorate(_ctx('aaa')).ranges, isEmpty);
      expect(plugin.decorate(_ctx('bbb')).ranges, hasLength(3));
    });
  });
}
