import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

DecorationContext _ctx(String text) => DecorationContext(
      text: text,
      selection: const TextSelection.collapsed(offset: 0),
      composing: TextRange.empty,
      hasFocus: false,
    );

void main() {
  group('EffectsPlugin', () {
    test('iMessageScale returns large font for short text', () {
      final resolver = Effects.iMessageScale();
      final style = resolver('hi');
      expect(style?.fontSize, isNotNull);
      expect(style!.fontSize, greaterThan(20));
    });

    test('iMessageScale returns small font for long text', () {
      final resolver = Effects.iMessageScale();
      final style = resolver('a' * 200);
      expect(style?.fontSize, lessThan(20));
    });

    test('iMessageScale interpolates between thresholds', () {
      final resolver = Effects.iMessageScale(
        shortFontSize: 30,
        longFontSize: 15,
        shortThreshold: 10,
        mediumThreshold: 50,
      );
      final short = resolver('abc');
      final mid = resolver('a' * 30);
      final long = resolver('a' * 100);
      expect(short!.fontSize, 30);
      expect(mid!.fontSize, inExclusiveRange(15, 30));
      expect(long!.fontSize, 15);
    });

    test('shouting preset matches 3+ uppercase letters', () {
      final plugin = EffectsPlugin(effects: [Effects.shouting()]);
      final result = plugin.decorate(_ctx('hi YES that was LOUD'));
      expect(result.ranges, hasLength(2));
    });

    test('numbers preset matches integers and decimals', () {
      final plugin = EffectsPlugin(effects: [Effects.numbers()]);
      final result = plugin.decorate(_ctx('a 1 and 2.5 here'));
      expect(result.ranges, hasLength(2));
    });
  });
}
