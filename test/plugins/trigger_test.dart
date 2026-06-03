import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

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

void main() {
  group('SlashCommandPlugin', () {
    test('detects active query after / at start', () async {
      final plugin = SlashCommandPlugin(
        commands: const [
          SlashCommand(name: 'help', description: 'Help me'),
          SlashCommand(name: 'home', description: 'Go home'),
        ],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = '/h';
      controller.selection = const TextSelection.collapsed(offset: 2);
      await Future<void>.delayed(Duration.zero);

      expect(plugin.activeQuery, isNotNull);
      expect(plugin.activeQuery!.query, 'h');
      expect(plugin.currentSuggestions, hasLength(2));
    });

    test('does not activate when preceded by a non-whitespace char', () async {
      final plugin = SlashCommandPlugin(
        commands: const [SlashCommand(name: 'foo', description: '')],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = 'a/f';
      controller.selection = const TextSelection.collapsed(offset: 3);
      await Future<void>.delayed(Duration.zero);

      expect(plugin.activeQuery, isNull);
    });

    test('closeOnSpace closes the popup when a space is typed', () async {
      final plugin = SlashCommandPlugin(
        commands: const [SlashCommand(name: 'foo', description: '')],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = '/f';
      controller.selection = const TextSelection.collapsed(offset: 2);
      await Future<void>.delayed(Duration.zero);
      expect(plugin.isOpen, isTrue);

      controller.text = '/f ';
      controller.selection = const TextSelection.collapsed(offset: 3);
      await Future<void>.delayed(Duration.zero);
      expect(plugin.isOpen, isFalse);
    });

    test('selectNext / selectPrevious cycle', () async {
      final plugin = SlashCommandPlugin(
        commands: const [
          SlashCommand(name: 'a', description: ''),
          SlashCommand(name: 'b', description: ''),
          SlashCommand(name: 'c', description: ''),
        ],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = '/';
      controller.selection = const TextSelection.collapsed(offset: 1);
      await Future<void>.delayed(Duration.zero);
      expect(plugin.selectedIndex, 0);
      plugin.selectNext();
      expect(plugin.selectedIndex, 1);
      plugin.selectPrevious();
      expect(plugin.selectedIndex, 0);
      plugin.selectPrevious();
      expect(plugin.selectedIndex, 2);
    });

    test('default accept replaces trigger range with insertText', () async {
      final plugin = SlashCommandPlugin(
        commands: const [SlashCommand(name: 'help', description: '')],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = '/hel';
      controller.selection = const TextSelection.collapsed(offset: 4);
      await Future<void>.delayed(Duration.zero);
      plugin.acceptSelected();
      expect(controller.text, '/help ');
      expect(controller.selection.extent.offset, 6);
    });

    testWidgets('Enter key from the field accepts the suggestion',
        (tester) async {
      final plugin = SlashCommandPlugin(
        commands: const [SlashCommand(name: 'help', description: '')],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _Host(
          child: InteractiveTextField(
            controller: controller,
            autofocus: true,
          ),
        ),
      );
      controller.text = '/he';
      controller.selection = const TextSelection.collapsed(offset: 3);
      await tester.pumpAndSettle();
      expect(plugin.isOpen, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.text, '/help ');
      expect(plugin.isOpen, isFalse);
    });
  });

  group('MentionPlugin', () {
    test('detects @ trigger', () async {
      final plugin = MentionPlugin(
        mentions: const [
          Mention(id: '1', displayName: 'Rob', handle: 'rob'),
          Mention(id: '2', displayName: 'Alex', handle: 'alex'),
        ],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = 'hi @r';
      controller.selection = const TextSelection.collapsed(offset: 5);
      await Future<void>.delayed(Duration.zero);

      expect(plugin.isOpen, isTrue);
      expect(plugin.currentSuggestions, hasLength(1));
    });

    test('accepting a mention inserts the handle', () async {
      final plugin = MentionPlugin(
        mentions: const [
          Mention(id: '1', displayName: 'Rob', handle: 'rob'),
        ],
      );
      final controller = InteractiveTextController(plugins: [plugin]);
      addTearDown(controller.dispose);

      controller.text = 'hi @';
      controller.selection = const TextSelection.collapsed(offset: 4);
      await Future<void>.delayed(Duration.zero);
      plugin.acceptSelected();
      expect(controller.text, 'hi @rob ');
    });
  });
}
