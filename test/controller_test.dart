import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class _CountingPlugin extends InteractiveTextPlugin {
  int textChanges = 0;
  int selectionChanges = 0;
  int attached = 0;
  int detached = 0;

  @override
  void onAttach() => attached++;

  @override
  void onDetach() => detached++;

  @override
  void onTextChanged(TextChange change) => textChanges++;

  @override
  void onSelectionChanged(TextSelection selection) => selectionChanges++;
}

class _UppercaseTransformPlugin extends InteractiveTextPlugin {
  @override
  TextEditingValue transformValue(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _StaticRangePlugin extends InteractiveTextPlugin {
  _StaticRangePlugin(this.range);
  final StyledRange range;

  @override
  DecorationResult decorate(DecorationContext ctx) =>
      DecorationResult([range]);
}

void main() {
  group('InteractiveTextController', () {
    testWidgets('notifies plugins of text and selection changes',
        (tester) async {
      final p = _CountingPlugin();
      final c = InteractiveTextController(plugins: [p]);
      addTearDown(c.dispose);

      expect(p.attached, 1);
      c.text = 'hello';
      c.selection = const TextSelection.collapsed(offset: 5);
      await tester.pump();
      expect(p.textChanges, 1);
      expect(p.selectionChanges, greaterThanOrEqualTo(1));
    });

    test('detaches plugins on dispose', () {
      final p = _CountingPlugin();
      final c = InteractiveTextController(plugins: [p]);
      c.dispose();
      expect(p.detached, 1);
      expect(p.isAttached, isFalse);
    });

    test('addPlugin and removePlugin work', () {
      final c = InteractiveTextController();
      addTearDown(c.dispose);
      final p = _CountingPlugin();
      c.addPlugin(p);
      expect(c.plugins, contains(p));
      expect(p.attached, 1);
      c.removePlugin(p);
      expect(c.plugins, isNot(contains(p)));
      expect(p.detached, 1);
    });

    test('findPlugin returns correct plugin by type', () {
      final p = _CountingPlugin();
      final c = InteractiveTextController(plugins: [p]);
      addTearDown(c.dispose);
      expect(c.findPlugin<_CountingPlugin>(), same(p));
      expect(c.findPlugin<RegexHighlightPlugin>(), isNull);
    });

    testWidgets('applyTransforms runs on value mutation', (tester) async {
      final c = InteractiveTextController(
        plugins: [_UppercaseTransformPlugin()],
      );
      addTearDown(c.dispose);
      c.text = 'hello';
      await tester.pump();
      expect(c.text, 'HELLO');
    });

    testWidgets('buildTextSpan reflects plugin decorations', (tester) async {
      final c = InteractiveTextController(
        text: 'abc',
        plugins: [
          _StaticRangePlugin(
            StyledRange(
              start: 0,
              end: 3,
              style: const TextStyle(color: Color(0xFFAABBCC)),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);

      late TextSpan span;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              span = c.buildTextSpan(context: context, withComposing: false);
              return const SizedBox();
            },
          ),
        ),
      );
      final children = (span.children ?? const <InlineSpan>[]).cast<TextSpan>();
      expect(children, hasLength(1));
      expect(children.first.style?.color, const Color(0xFFAABBCC));
    });
  });
}
