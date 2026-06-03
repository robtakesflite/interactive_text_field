import 'package:flutter/material.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

class MessageBubbleDemo extends StatefulWidget {
  const MessageBubbleDemo({super.key});

  @override
  State<MessageBubbleDemo> createState() => _MessageBubbleDemoState();
}

class _Message {
  _Message({required this.text, required this.fromMe});
  final String text;
  final bool fromMe;
}

class _MessageBubbleDemoState extends State<MessageBubbleDemo> {
  late final InteractiveTextController _input;
  final _messages = <_Message>[
    _Message(text: 'Hey! Check out **interactive_text_field**.', fromMe: false),
    _Message(text: 'It supports `code`, *italic*, and #hashtags inline.', fromMe: true),
  ];

  @override
  void initState() {
    super.initState();
    _input = InteractiveTextController(
      plugins: [
        MarkdownPlugin(),
        RegexHighlightPlugin(rules: [
          CommonRegexRules.url(),
          CommonRegexRules.hashtag(),
        ]),
      ],
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text, fromMe: true));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, i) => _Bubble(message: _messages[i]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: InteractiveTextField(
                  controller: _input,
                  maxLines: 6,
                  minLines: 1,
                  cursorColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _send,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({required this.message});
  final _Message message;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> {
  late final InteractiveTextController _controller;
  late final TextStyle _baseStyle;

  Color get _bubbleColor => widget.message.fromMe
      ? const Color(0xFF1976D2)
      : const Color(0xFFE9E9EB);

  Color get _textColor => widget.message.fromMe
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF1F1F1F);

  @override
  void initState() {
    super.initState();
    _baseStyle = TextStyle(color: _textColor, fontSize: 16, height: 1.3);
    _controller = InteractiveTextController(
      plugins: [
        MarkdownPlugin(
          style: MarkdownStyle(
            bold: const TextStyle(fontWeight: FontWeight.bold),
            italic: const TextStyle(fontStyle: FontStyle.italic),
            inlineCode: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: widget.message.fromMe
                  ? const Color(0x33FFFFFF)
                  : const Color(0x14000000),
            ),
            link: TextStyle(
              color: _textColor,
              decoration: TextDecoration.underline,
            ),
            delimiter:
                TextStyle(color: _textColor.withValues(alpha: 0.4)),
          ),
        ),
        RegexHighlightPlugin(rules: [
          CommonRegexRules.url(
            style: TextStyle(
              color: _textColor,
              decoration: TextDecoration.underline,
            ),
          ),
          CommonRegexRules.hashtag(
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ],
      text: widget.message.text,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.message.fromMe
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _bubbleColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: InteractiveTextField(
          controller: _controller,
          readOnly: true,
          enableInteractiveSelection: false,
          maxLines: null,
          showCursor: false,
          style: _baseStyle,
        ),
      ),
    );
  }
}
