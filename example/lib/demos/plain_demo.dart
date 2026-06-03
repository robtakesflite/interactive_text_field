import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class PlainDemo extends StatefulWidget {
  const PlainDemo({super.key});

  @override
  State<PlainDemo> createState() => _PlainDemoState();
}

class _PlainDemoState extends State<PlainDemo> {
  late final InteractiveTextController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InteractiveTextController(text: 'Type anything here.');
    _controller.addListener(_onChange);
  }

  void _onChange() => setState(() {});

  @override
  void dispose() {
    _controller.removeListener(_onChange);
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
            'The bare field: no plugins, no Material chrome.',
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
          const SizedBox(height: 8),
          Text(
            'Characters: ${_controller.text.length}',
            style: const TextStyle(color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => _controller.clear(),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
