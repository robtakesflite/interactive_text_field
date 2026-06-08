import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/material.dart';

void main() {
  group('MaterialInteractiveTextField', () {
    testWidgets('resolves cursor + selection from ThemeData', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const seed = Color(0xFFAB1234);
      final theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        useMaterial3: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: MaterialInteractiveTextField(controller: controller),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, theme.colorScheme.primary);
    });

    testWidgets('explicit cursorColor overrides theme', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const override = Color(0xFF00FF00);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialInteractiveTextField(
              controller: controller,
              cursorColor: override,
            ),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, override);
    });

    testWidgets('uses TextSelectionTheme cursorColor when set', (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const cursor = Color(0xFFFE00AA);
      final theme = ThemeData(
        textSelectionTheme: const TextSelectionThemeData(cursorColor: cursor),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: MaterialInteractiveTextField(controller: controller),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.cursorColor, cursor);
    });

    testWidgets('accepts typed text end-to-end', (tester) async {
      final controller = InteractiveTextController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialInteractiveTextField(
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

    testWidgets('inherits text style from theme.textTheme.bodyLarge',
        (tester) async {
      final controller = InteractiveTextController(text: 'hello');
      addTearDown(controller.dispose);

      const bodyLarge = TextStyle(fontSize: 22, color: Color(0xFF112233));
      final theme = ThemeData(
        textTheme: const TextTheme(bodyLarge: bodyLarge),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: MaterialInteractiveTextField(controller: controller),
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontSize, bodyLarge.fontSize);
      expect(editable.style.color, bodyLarge.color);
    });
  });
}
