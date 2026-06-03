import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class MarkdownDemo extends StatefulWidget {
  const MarkdownDemo({super.key});

  @override
  State<MarkdownDemo> createState() => _MarkdownDemoState();
}

class _MarkdownDemoState extends State<MarkdownDemo> {
  late InteractiveTextController _controller;
  MarkdownMode _mode = MarkdownMode.editor;

  static const _sample = '''
# A Note on Fishing

This is **bold**, _italic_, and ***bold-italic***.
Use `inlineCode` for monospace.
Strike ~~old fish~~ from your list.

[Open the docs](https://example.com)

> The best time was yesterday; the next best is now.

- Hook
- Line
- Sinker

```dart
class Fish {
  final String name;
  final int weight;
  bool get isBig => weight >= 1000;
}
```

```sql
SELECT species, name, weight
FROM catches
WHERE weight > 500
ORDER BY weight DESC;
```
''';

  @override
  void initState() {
    super.initState();
    _controller = _build(_mode);
  }

  InteractiveTextController _build(MarkdownMode mode) {
    return InteractiveTextController(
      plugins: [MarkdownPlugin(mode: mode)],
      text: _sample,
    );
  }

  void _setMode(MarkdownMode mode) {
    if (mode == _mode) return;
    final oldController = _controller;
    setState(() {
      _mode = mode;
      _controller = _build(mode);
    });
    oldController.dispose();
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
          SegmentedButton<MarkdownMode>(
            segments: const [
              ButtonSegment(
                value: MarkdownMode.editor,
                label: Text('Editor'),
                icon: Icon(Icons.edit_outlined),
              ),
              ButtonSegment(
                value: MarkdownMode.viewer,
                label: Text('Viewer'),
                icon: Icon(Icons.visibility_outlined),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => _setMode(s.first),
          ),
          const SizedBox(height: 8),
          Text(
            _mode == MarkdownMode.editor
                ? 'Editor mode: markers (#, **, `, ```lang) stay visible but dimmed.'
                : 'Viewer mode: markers collapse — reads like rendered markdown.',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: InteractiveTextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              cursorColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1F1F1F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
