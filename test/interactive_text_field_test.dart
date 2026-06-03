import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

void main() {
  group('InteractiveTextField smoke', () {
    testWidgets('renders plain text and exposes controller text', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(child: InteractiveTextField(controller: controller)),
      );

      expect(find.byType(InteractiveTextField), findsOneWidget);
      expect(controller.text, 'hello');
    });

    testWidgets('user input updates controller', (tester) async {
      final controller = InteractiveTextController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          child: InteractiveTextField(
            controller: controller,
            autofocus: true,
          ),
        ),
      );
      await tester.enterText(find.byType(InteractiveTextField), 'hi there');
      await tester.pump();
      expect(controller.text, 'hi there');
    });

    testWidgets('regex plugin produces a colored span', (tester) async {
      final regex = RegexHighlightPlugin(rules: [
        RegexHighlightRule(
          pattern: RegExp(r'\bTODO\b'),
          style: const TextStyle(color: Color(0xFFFF0000)),
        ),
      ]);
      final controller = InteractiveTextController(
        text: 'a TODO here',
        plugins: [regex],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(child: InteractiveTextField(controller: controller)),
      );

      final span = controller.buildTextSpan(
        context: tester.element(find.byType(InteractiveTextField)),
        withComposing: false,
      );
      final children = (span.children ?? <InlineSpan>[]).cast<TextSpan>();
      final hasRed = children.any(
        (s) => s.style?.color == const Color(0xFFFF0000) && s.text == 'TODO',
      );
      expect(hasRed, isTrue);
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
