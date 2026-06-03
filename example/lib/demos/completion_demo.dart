import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class CompletionDemo extends StatefulWidget {
  const CompletionDemo({super.key});

  @override
  State<CompletionDemo> createState() => _CompletionDemoState();
}

class _CompletionDemoState extends State<CompletionDemo> {
  late final InteractiveTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InteractiveTextController(
      plugins: [
        CompletionPlugin(
          provider: const StaticListCompletionProvider([
            'abstract', 'argument', 'asynchronous', 'await',
            'because', 'before', 'behavior',
            'closure', 'continuation', 'controller',
            'decorate', 'declarative', 'definition', 'delegate',
            'editor', 'efficient', 'elegant', 'event',
            'factory', 'foundation', 'framework', 'function',
            'generic', 'gesture', 'gradient',
            'handler', 'highlight', 'history',
            'immutable', 'implementation', 'inline', 'interactive',
            'language', 'listener', 'literal',
            'metadata', 'mixin', 'modular',
            'namespace', 'navigator', 'notification',
            'observer', 'opacity', 'overlay',
            'package', 'parameter', 'paragraph', 'plugin', 'priority',
            'render', 'rendered', 'rendering', 'resolver',
            'selection', 'snapshot', 'subscription', 'syntax',
            'template', 'trigger', 'transition',
            'unique', 'universe',
            'value', 'vector', 'viewport',
            'widget', 'window',
          ]),
        ),
      ],
      text: 'Start typing a word… try "func" or "wid" or "trig"',
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
            'Ghost-text inline completion. Press Tab to accept the\n'
            'currently-shown suggestion. Esc to dismiss.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          InteractiveTextField(
            controller: _controller,
            autofocus: true,
            maxLines: 6,
            cursorColor: const Color(0xFF1976D2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
          ),
          const SizedBox(height: 8),
          const Text(
            'For AI completion: pass an async CompletionProvider that\n'
            'talks to your LLM — same UI, same keybindings.',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
