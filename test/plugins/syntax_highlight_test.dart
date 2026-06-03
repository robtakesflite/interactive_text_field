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
  group('SyntaxHighlightPlugin', () {
    test('produces ranges for Dart source', () {
      final plugin = SyntaxHighlightPlugin(language: SyntaxLanguages.dart);
      final result = plugin.decorate(_ctx(
        'class Foo { void bar() {} }',
      ));
      expect(result.ranges, isNotEmpty);
    });

    test('produces ranges for SQL', () {
      final plugin = SyntaxHighlightPlugin(language: SyntaxLanguages.sql);
      final result = plugin.decorate(_ctx('SELECT * FROM users;'));
      expect(result.ranges, isNotEmpty);
    });

    test('returns empty when no language and no auto detection', () {
      final plugin = SyntaxHighlightPlugin();
      expect(plugin.decorate(_ctx('int x = 1;')).ranges, isEmpty);
    });

    test('changing language re-emits', () {
      final plugin = SyntaxHighlightPlugin(language: SyntaxLanguages.dart);
      final first = plugin.decorate(_ctx('var x = 1;')).ranges;
      plugin.language = SyntaxLanguages.python;
      final second = plugin.decorate(_ctx('def f(): pass')).ranges;
      expect(first, isNotEmpty);
      expect(second, isNotEmpty);
    });

    test('handles empty text gracefully', () {
      final plugin = SyntaxHighlightPlugin(language: SyntaxLanguages.dart);
      expect(plugin.decorate(_ctx('')).ranges, isEmpty);
    });

    test('priority is preserved on emitted ranges', () {
      final plugin = SyntaxHighlightPlugin(
        language: SyntaxLanguages.dart,
        priority: 42,
      );
      final result = plugin.decorate(_ctx('int x = 1;'));
      expect(result.ranges.first.priority, 42);
    });
  });
}
