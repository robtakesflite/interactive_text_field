import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/cupertino.dart';

void main() {
  group('CupertinoInteractiveTextField', () {
    testWidgets('resolves cursor color from CupertinoTheme', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const primary = Color(0xFF112233);
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(primaryColor: primary),
          home: CupertinoPageScaffold(
            child: CupertinoInteractiveTextField(controller: controller),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, primary);
    });

    testWidgets('explicit cursorColor overrides theme', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const override = Color(0xFFFF00FF);
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: CupertinoInteractiveTextField(
              controller: controller,
              cursorColor: override,
            ),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, override);
    });

    testWidgets('inherits text style from CupertinoTheme.textTheme',
        (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const textStyle = TextStyle(fontSize: 19, color: Color(0xFF445566));
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            textTheme: CupertinoTextThemeData(textStyle: textStyle),
          ),
          home: CupertinoPageScaffold(
            child: CupertinoInteractiveTextField(controller: controller),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontSize, textStyle.fontSize);
      expect(editable.style.color, textStyle.color);
    });

    testWidgets('accepts typed text end-to-end', (tester) async {
      final controller = InteractiveTextController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: CupertinoInteractiveTextField(
              controller: controller,
              autofocus: true,
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'hello');
      await tester.pump();
      expect(controller.text, 'hello');
    });

    testWidgets('uses Cupertino default cursor radius', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: CupertinoInteractiveTextField(controller: controller),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorRadius, const Radius.circular(2.0));
    });
  });
}
