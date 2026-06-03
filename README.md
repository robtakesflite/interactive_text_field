# interactive_text_field

A modular, framework-agnostic interactive text field for Flutter. Built on
Flutter's primitive `EditableText` — **no Material or Cupertino dependency**.
Behavior is contributed by plugins, so you can mix and match syntax
highlighting, markdown styling, slash-commands, mentions, code completion,
and live "iMessage" effects in any combination.

## Highlights

- **Plugin-based.** Decoration is contributed by independent
  `InteractiveTextPlugin`s. The controller merges them by priority into a
  single `TextSpan` tree — order-independent, override-able, composable.
- **Syntax highlighting** for 180+ languages via the
  [`highlight`](https://pub.dev/packages/highlight) package: Dart, SQL,
  Python, Rust, HTML, JSON, YAML, Bash, …
- **Inline markdown** styling without rendering a parallel widget tree —
  `**bold**`, `_italic_`, `` `code` ``, `[links](url)`, headings, lists,
  blockquotes. Delimiters dim so syntax stays visible, not noisy.
- **Regex highlighting** for URLs, emails, hashtags, mentions, custom
  patterns. Bring your own `RegExp` and `TextStyle`.
- **Slash commands** (`/help`, `/clear`) and **`@mentions`** with popup
  navigation, keyboard accept/cancel, custom row builders.
- **Inline code completion** with a `CompletionProvider` interface — drop
  in a static list, hook up an LLM, or both via `CompositeCompletionProvider`.
- **Live "iMessage" effects** — short messages grow, long messages shrink,
  emoji-only messages get especially large, ALL-CAPS bolds up. Animated
  base-style transitions out of the box.
- **Framework-neutral.** Style with `Container`, `BoxDecoration`, or your
  own design system. There is a runtime test guarding against accidental
  `material.dart` / `cupertino.dart` imports.

## Install

```yaml
dependencies:
  interactive_text_field:
    git:
      url: https://github.com/robertmollentze/interactive_text_field
```

## Quick start

```dart
import 'package:flutter/widgets.dart';
import 'package:interactive_text_field/interactive_text_field.dart';

final controller = InteractiveTextController(
  plugins: [
    MarkdownPlugin(),
    RegexHighlightPlugin(rules: [
      CommonRegexRules.url(),
      CommonRegexRules.hashtag(),
    ]),
    SyntaxHighlightPlugin(language: SyntaxLanguages.dart),
  ],
);

InteractiveTextField(
  controller: controller,
  maxLines: 8,
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: const Color(0xFFFAFAFA),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE0E0E0)),
  ),
  style: const TextStyle(fontSize: 16, color: Color(0xFF1F1F1F)),
);
```

## Plugins

### `RegexHighlightPlugin`

Colors regex matches. Ships with `CommonRegexRules` for URLs, emails,
hashtags, and mentions.

```dart
RegexHighlightPlugin(rules: [
  CommonRegexRules.url(),
  RegexHighlightRule(
    pattern: RegExp(r'\b(TODO|FIXME)\b'),
    style: TextStyle(color: Color(0xFFD32F2F), fontWeight: FontWeight.bold),
  ),
]);
```

### `SyntaxHighlightPlugin`

180+ languages via `highlight`. Two themes shipped (`githubLight`,
`vsCodeDark`); themes are just `Map<String, TextStyle>`, so build your own.

```dart
SyntaxHighlightPlugin(
  language: SyntaxLanguages.dart,
  theme: SyntaxThemes.vsCodeDark,
);
```

### `MarkdownPlugin`

Inline-only — styles spans in place without rewriting them. Includes
delimiter dimming.

```dart
MarkdownPlugin(style: MarkdownStyle.defaults);
```

### `SlashCommandPlugin` / `MentionPlugin`

Both extend `TriggerPlugin`. Provide a list, the plugin handles detection,
filtering, popup rendering, and keyboard navigation.

```dart
SlashCommandPlugin(
  commands: const [
    SlashCommand(name: 'help', description: 'Show available commands'),
    SlashCommand(name: 'clear', description: 'Clear the input'),
  ],
);

MentionPlugin(
  mentions: [
    Mention(id: '1', displayName: 'Rob', handle: 'rob', avatar: ...),
  ],
);
```

For a custom trigger character (e.g. `#` for tags), instantiate
`TriggerPlugin<T>` directly.

### `CompletionPlugin`

Inline ghost-text. Press Tab to accept. The same UI works for static
word lists or async LLM-backed completion.

```dart
CompletionPlugin(
  provider: const StaticListCompletionProvider(['async', 'await', 'class']),
);

// Mix sync and async:
CompositeCompletionProvider([
  const StaticListCompletionProvider([...]),
  MyLlmCompletionProvider(),
]);
```

### `EffectsPlugin`

Live, content-driven effects. Combine a `BaseStyleResolver` (global style
that depends on the entire text) with `PatternEffect`s (range styles that
depend on a regex match).

```dart
EffectsPlugin(
  baseStyleResolver: Effects.iMessageScale(),
  effects: [
    Effects.shouting(),
    Effects.emojiPop(),
    Effects.numbers(),
  ],
);
```

`InteractiveTextField` smoothly animates the base style as it changes — so
when the user transitions from `"hi"` to a long paragraph the text shrinks
in a single transition instead of snapping.

> **Animation scope.** Only the global base style is animated. Per-range
> style changes (e.g. a word becoming bold when its `**` closes) apply
> immediately to keep the editor responsive to fast typing.

## Custom plugins

```dart
class HighlightAllAs extends InteractiveTextPlugin {
  HighlightAllAs(this.style);
  final TextStyle style;

  @override
  DecorationResult decorate(DecorationContext ctx) {
    final ranges = <StyledRange>[];
    for (var i = 0; i < ctx.text.length; i++) {
      if (ctx.text[i].toLowerCase() == 'a') {
        ranges.add(StyledRange(start: i, end: i + 1, style: style));
      }
    }
    return DecorationResult(ranges);
  }
}
```

Plugins can also:

- Mutate text via `context.writeValue(...)` — used by `TriggerPlugin` and
  `CompletionPlugin` to commit accepted suggestions.
- Intercept keys via `onKeyEvent`.
- Contribute global style overrides via `overrideBaseStyle`.
- Show overlays (popups, suggestion menus) via `buildOverlay`.

## Examples

See `example/` for one screen per feature: plain field, regex
highlighting, syntax highlighting, markdown, slash commands, mentions,
inline completion, message bubbles, and iMessage-style live effects.

```bash
cd example
flutter run
```

## Testing

```bash
flutter test
```

The package ships with widget tests, plugin unit tests, and a guard test
that fails the suite if any source file in `lib/` imports `material.dart`
or `cupertino.dart`.

## License

MIT.
