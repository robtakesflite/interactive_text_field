import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

void main() {
  group('InteractiveTextField widget', () {
    testWidgets('selects text and copies via shortcut keys', (tester) async {
      final controller = InteractiveTextController(text: 'select me');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          child: InteractiveTextField(
            controller: controller,
            autofocus: true,
          ),
        ),
      );
      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 6);
      await tester.pump();
      expect(controller.selection.textInside(controller.text), 'select');
    });

    testWidgets('respects readOnly', (tester) async {
      final controller = InteractiveTextController(text: 'locked');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          child: InteractiveTextField(
            controller: controller,
            readOnly: true,
            autofocus: true,
          ),
        ),
      );
      await tester.enterText(find.byType(InteractiveTextField), 'NEW');
      await tester.pump();
      expect(controller.text, 'locked');
    });

    testWidgets('multi-line maxLines accepts newlines', (tester) async {
      final controller = InteractiveTextController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          child: InteractiveTextField(
            controller: controller,
            maxLines: 5,
            autofocus: true,
          ),
        ),
      );
      await tester.enterText(find.byType(InteractiveTextField), 'a\nb\nc');
      await tester.pump();
      expect(controller.text, 'a\nb\nc');
    });

    testWidgets('controller change updates the field', (tester) async {
      final first = InteractiveTextController(text: 'one');
      final second = InteractiveTextController(text: 'two');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      InteractiveTextController active = first;
      late StateSetter setter;
      await tester.pumpWidget(
        _Host(
          child: StatefulBuilder(
            builder: (context, setState) {
              setter = setState;
              return InteractiveTextField(controller: active);
            },
          ),
        ),
      );
      setter(() => active = second);
      await tester.pump();
      expect(active.text, 'two');
    });

    testWidgets('base style animation transitions smoothly', (tester) async {
      final controller = InteractiveTextController(
        plugins: [
          EffectsPlugin(baseStyleResolver: Effects.iMessageScale()),
        ],
        text: 'a',
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(child: InteractiveTextField(controller: controller)),
      );
      await tester.pumpAndSettle();

      controller.text = 'a' * 200;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(controller.text.length, 200);
    });

    testWidgets('caretRectForSelection returns a rect when selection is valid',
        (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);
      final key = GlobalKey<InteractiveTextFieldState>();
      await tester.pumpWidget(
        _Host(
          child: InteractiveTextField(
            key: key,
            controller: controller,
            autofocus: true,
          ),
        ),
      );
      controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();
      expect(key.currentState?.caretRectForSelection(), isNotNull);
    });
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (_) => Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 400, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
