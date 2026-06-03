import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class RegexDemo extends StatefulWidget {
  const RegexDemo({super.key});

  @override
  State<RegexDemo> createState() => _RegexDemoState();
}

class _RegexDemoState extends State<RegexDemo> {
  late final InteractiveTextController _controller;
  late final RegexHighlightPlugin _plugin;

  @override
  void initState() {
    super.initState();
    _plugin = RegexHighlightPlugin(rules: [
      CommonRegexRules.url(),
      CommonRegexRules.email(),
      CommonRegexRules.hashtag(),
      CommonRegexRules.mention(),
      RegexHighlightRule(
        pattern: RegExp(r'\b(TODO|FIXME|NOTE)\b'),
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontWeight: FontWeight.bold,
        ),
        priority: 20,
      ),
      RegexHighlightRule(
        pattern: RegExp(r'\b\d{4}-\d{2}-\d{2}\b'),
        style: const TextStyle(
          color: Color(0xFF6D4C41),
          backgroundColor: Color(0xFFFFF8E1),
        ),
      ),
    ]);
    _controller = InteractiveTextController(
      plugins: [_plugin],
      text:
          'Visit https://example.com or email me@example.com\n'
          'Saying hi to @everyone with #great news.\n'
          'TODO: ship the demo by 2026-06-30.',
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
            'URLs, emails, #hashtags, @mentions, dates, and TODOs all\n'
            'styled live as you type.',
            style: TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          InteractiveTextField(
            controller: _controller,
            maxLines: 8,
            cursorColor: const Color(0xFF1976D2),
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
