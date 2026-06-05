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

    test('iMessageScale steps through tiers by length', () {
      final resolver = Effects.iMessageScale(
        hugeFontSize: 40,
        largeFontSize: 30,
        mediumFontSize: 20,
        longFontSize: 12,
        hugeMax: 3,
        largeMax: 10,
        mediumMax: 30,
      );
      expect(resolver('hi')!.fontSize, 40); // huge
      expect(resolver('abcdef')!.fontSize, 30); // large
      expect(resolver('a' * 20)!.fontSize, 20); // medium
      expect(resolver('a' * 100)!.fontSize, 12); // long
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

    test('matched ranges fade in via color alpha (paint-only)', () async {
      // shouting target color is solid red; appearance starts at a
      // reduced alpha and grows to full opacity. fontSize is NOT
      // animated, so the surrounding line never reflows.
      final plugin =
          EffectsPlugin(effects: [Effects.shouting(pulse: null)]);
      final first = plugin.decorate(_ctx('WOW'));
      expect(first.ranges, hasLength(1));
      final firstColor = first.ranges.first.style.color!;
      // Style does not declare a fontSize — paint-only effect.
      expect(first.ranges.first.style.fontSize, isNull);
      // ignore: deprecated_member_use
      expect(firstColor.opacity, lessThan(1.0));
      // ignore: deprecated_member_use
      expect(firstColor.opacity, greaterThanOrEqualTo(0.4));

      // Wait past the appearance window and re-decorate — same range key,
      // so the animation has finished and the style is fully resolved.
      await Future<void>.delayed(const Duration(milliseconds: 320));
      final settled = plugin.decorate(_ctx('WOW'));
      // ignore: deprecated_member_use
      expect(settled.ranges.first.style.color!.opacity, 1.0);
    });

    test('pulse cycles color after appearance settles', () async {
      final plugin = EffectsPlugin(effects: [
        Effects.shouting(
          appearDuration: const Duration(milliseconds: 0),
          pulse: const PulseEffect(
            duration: Duration(milliseconds: 200),
            colorMin: Color(0xFFFF0000),
            colorMax: Color(0xFF0000FF),
          ),
        ),
      ]);
      final colors = <int>{};
      for (var i = 0; i < 6; i++) {
        colors.add(
          // ignore: deprecated_member_use
          plugin.decorate(_ctx('WOW')).ranges.first.style.color!.value,
        );
        await Future<void>.delayed(const Duration(milliseconds: 35));
      }
      // If pulse is cycling color, we should see more than one value.
      expect(colors.length, greaterThan(1));
    });

    test('matched style declares no fontSize / fontWeight animation',
        () async {
      // Regression guard: animating layout-affecting properties on the
      // matched range causes the entire line to grow/shrink — the
      // "whole sentence is animating" bug we're guarding against.
      final plugin = EffectsPlugin(effects: [Effects.shouting()]);
      final sizes = <double?>{};
      final weights = <FontWeight?>{};
      for (var i = 0; i < 6; i++) {
        final r = plugin.decorate(_ctx('WOW')).ranges.first;
        sizes.add(r.style.fontSize);
        weights.add(r.style.fontWeight);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(sizes, {null}, reason: 'fontSize must never animate');
      expect(weights, {FontWeight.w900},
          reason: 'fontWeight must never animate');
    });
  });
}
