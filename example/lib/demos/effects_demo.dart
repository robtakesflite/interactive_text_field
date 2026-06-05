import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class EffectsDemo extends StatefulWidget {
  const EffectsDemo({super.key});

  @override
  State<EffectsDemo> createState() => _EffectsDemoState();
}

class _EffectsDemoState extends State<EffectsDemo> {
  late final InteractiveTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InteractiveTextController(
      plugins: [
        EffectsPlugin(
          effects: [
            Effects.shouting(),
            Effects.emojiPop(),
            Effects.numbers(),
          ],
        ),
      ],
      text: 'Type WOW or 42 or 🎉 to see effects fire.',
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
            'Per-pattern live effects — only matched ranges\n'
            'animate, and only with paint-only properties so\n'
            'the surrounding sentence never reflows:\n\n'
            '• ALL-CAPS → bold red, color pulses red↔coral.\n'
            '• Emoji → soft shadow, breathes 0.25↔0.75.\n'
            '• Numbers → bold blue, no pulse (static).\n\n'
            'Type WOW or 🎉 and watch only those words\n'
            'pulse — the rest of the line stays put.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          InteractiveTextField(
            controller: _controller,
            autofocus: true,
            maxLines: 8,
            minLines: 3,
            cursorColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
            baseStyleAnimationDuration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}
