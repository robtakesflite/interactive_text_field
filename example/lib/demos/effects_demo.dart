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
          baseStyleResolver: Effects.iMessageScale(),
          effects: [
            Effects.shouting(),
            Effects.emojiPop(),
            Effects.numbers(),
          ],
        ),
      ],
      text: 'Hi!',
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
            'iMessage-style live effects:\n'
            '• Short messages grow big.\n'
            '• Single-emoji messages get larger.\n'
            '• ALL-CAPS words bold up.\n'
            '• Numbers tint blue.\n\n'
            'Try typing "Hi!", then a long sentence,\n'
            'then just an emoji.',
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
