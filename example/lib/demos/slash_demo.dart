import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class SlashDemo extends StatefulWidget {
  const SlashDemo({super.key});

  @override
  State<SlashDemo> createState() => _SlashDemoState();
}

class _SlashDemoState extends State<SlashDemo> {
  late final InteractiveTextController _controller;
  late final SlashCommandPlugin _slash;
  String _log = 'No command yet — type "/" to start.';

  static const _commands = [
    SlashCommand(name: 'help', description: 'Show available commands'),
    SlashCommand(name: 'clear', description: 'Clear the input'),
    SlashCommand(name: 'bold', description: 'Insert **bold** placeholder'),
    SlashCommand(name: 'date', description: 'Insert the current date'),
    SlashCommand(name: 'fish', description: 'Mention your fishing log'),
    SlashCommand(name: 'mood', description: 'Set a mood emoji', aliases: ['emoji']),
  ];

  @override
  void initState() {
    super.initState();
    _slash = SlashCommandPlugin(
      commands: _commands,
      onAccept: (suggestion, query) {
        final cmd = suggestion.value;
        setState(() {
          _log = 'Invoked /${cmd.name}: ${cmd.description}';
        });
        // Default behavior: insert "/help " into the field.
        final state = _controller.value;
        final insert = '${suggestion.insertText ?? suggestion.label} ';
        final before = state.text.substring(0, query.triggerOffset);
        final after = state.text.substring(query.cursorOffset);
        _controller.value = TextEditingValue(
          text: '$before$insert$after',
          selection: TextSelection.collapsed(
            offset: before.length + insert.length,
          ),
        );
      },
    );
    _controller = InteractiveTextController(
      plugins: [_slash, RegexHighlightPlugin(rules: [CommonRegexRules.hashtag()])],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Type "/" at start-of-line or after a space to open the\n'
            'command popup. Arrows to navigate. Enter / Tab to accept.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          InteractiveTextField(
            controller: _controller,
            maxLines: 4,
            cursorColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_log),
          ),
        ],
      ),
    );
  }
}
