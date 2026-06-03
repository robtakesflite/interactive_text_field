import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class MentionDemo extends StatefulWidget {
  const MentionDemo({super.key});

  @override
  State<MentionDemo> createState() => _MentionDemoState();
}

class _MentionDemoState extends State<MentionDemo> {
  late final InteractiveTextController _controller;
  final _people = const [
    Mention(id: '1', displayName: 'Robert Mollentze', handle: 'robert', subtitle: 'iOS'),
    Mention(id: '2', displayName: 'Alex Chen', handle: 'alex', subtitle: 'Backend'),
    Mention(id: '3', displayName: 'Priya Patel', handle: 'priya', subtitle: 'Design'),
    Mention(id: '4', displayName: 'Sam Okafor', handle: 'sam', subtitle: 'PM'),
    Mention(id: '5', displayName: 'Maya Singh', handle: 'maya', subtitle: 'Mobile'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = InteractiveTextController(
      plugins: [
        MentionPlugin(
          mentions: _people
              .map((m) => Mention(
                    id: m.id,
                    displayName: m.displayName,
                    handle: m.handle,
                    subtitle: m.subtitle,
                    avatar: _Avatar(letter: m.displayName.substring(0, 1)),
                  ))
              .toList(),
        ),
        RegexHighlightPlugin(rules: [CommonRegexRules.mention()]),
      ],
      text: 'Hey, ping @',
    );
    _controller.selection =
        TextSelection.collapsed(offset: _controller.text.length);
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
            'Type "@" to surface the mention popup. Avatars are\n'
            'plain Widgets, so they can be Image, Icon, anything.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          InteractiveTextField(
            controller: _controller,
            autofocus: true,
            maxLines: 4,
            cursorColor: const Color(0xFF7B1FA2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter});
  final String letter;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: Color(0xFFD1C4E9),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Color(0xFF4527A0),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
