import 'package:flutter/material.dart';

import 'demos/code_demo.dart';
import 'demos/completion_demo.dart';
import 'demos/effects_demo.dart';
import 'demos/markdown_demo.dart';
import 'demos/mention_demo.dart';
import 'demos/message_bubble_demo.dart';
import 'demos/plain_demo.dart';
import 'demos/regex_demo.dart';
import 'demos/slash_demo.dart';

void main() {
  runApp(const InteractiveTextFieldExample());
}

class InteractiveTextFieldExample extends StatelessWidget {
  const InteractiveTextFieldExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'interactive_text_field',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1976D2)),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
        ),
      ),
      home: const _HomeScreen(),
    );
  }
}

class _Demo {
  const _Demo({
    required this.title,
    required this.subtitle,
    required this.builder,
  });
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

final _demos = <_Demo>[
  _Demo(
    title: 'Plain Field',
    subtitle: 'Bare InteractiveTextField — no plugins',
    builder: (_) => const PlainDemo(),
  ),
  _Demo(
    title: 'Regex Highlighting',
    subtitle: 'URLs, emails, hashtags, @mentions, custom regex',
    builder: (_) => const RegexDemo(),
  ),
  _Demo(
    title: 'Syntax Highlighting',
    subtitle: 'Dart, SQL, Python, Rust, HTML, JSON, …',
    builder: (_) => const CodeDemo(),
  ),
  _Demo(
    title: 'Markdown',
    subtitle: 'Inline **bold**, _italic_, `code`, [links](url), # headings',
    builder: (_) => const MarkdownDemo(),
  ),
  _Demo(
    title: 'Slash Commands',
    subtitle: 'Notion-style /commands with popup',
    builder: (_) => const SlashDemo(),
  ),
  _Demo(
    title: 'Mentions',
    subtitle: '@-mentions with avatars',
    builder: (_) => const MentionDemo(),
  ),
  _Demo(
    title: 'Code Completion',
    subtitle: 'Inline ghost-text suggestions (Tab to accept)',
    builder: (_) => const CompletionDemo(),
  ),
  _Demo(
    title: 'Message Bubble',
    subtitle: 'iMessage-style chat input + rich bubbles',
    builder: (_) => const MessageBubbleDemo(),
  ),
  _Demo(
    title: 'Live Effects',
    subtitle: 'iMessage-style scaling + animated style transitions',
    builder: (_) => const EffectsDemo(),
  ),
];

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('interactive_text_field')),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _demos.length,
        separatorBuilder: (_, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final demo = _demos[index];
          return ListTile(
            title: Text(demo.title),
            subtitle: Text(demo.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DemoScaffold(
                  title: demo.title,
                  child: Builder(builder: demo.builder),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DemoScaffold extends StatelessWidget {
  const DemoScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(child: child),
    );
  }
}
