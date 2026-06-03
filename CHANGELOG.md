## 0.1.0

Initial release.

* `InteractiveTextField` widget built on Flutter's `EditableText` — no
  Material or Cupertino dependency.
* `InteractiveTextController` with plugin registry and range-merge span
  composition (priority-based, order-independent).
* `InteractiveTextPlugin` base class with `decorate`, `onTextChanged`,
  `onSelectionChanged`, `transformValue`, `onKeyEvent`, `buildOverlay`,
  and `overrideBaseStyle` hooks.
* Plugins:
  * `RegexHighlightPlugin` with `CommonRegexRules` (URL, email, hashtag,
    mention).
  * `SyntaxHighlightPlugin` with 13 hand-tuned built-in grammars
    (Dart, JavaScript, TypeScript, Python, Rust, Go, SQL, HTML, CSS,
    JSON, YAML, Bash, Markdown) and `githubLight` / `vsCodeDark`
    themes. Extensible via `GrammarRegistry.register`.
  * `MarkdownPlugin` for inline bold/italic/code/strike/link/heading/
    blockquote/list styling with dimmed delimiters.
  * `TriggerPlugin<T>` base for `/` and `@` style commands, with popup
    overlay, keyboard navigation, and default-substitute behavior.
  * `SlashCommandPlugin` and `MentionPlugin` as drop-in subclasses.
  * `CompletionPlugin` with `CompletionProvider` interface (sync, async,
    or composite), inline ghost-text rendering, Tab-to-accept.
  * `EffectsPlugin` with iMessage-style scale resolver, ALL-CAPS
    detection, emoji pop, and number tinting presets.
* `InteractiveTextField` animates base-style transitions when plugins
  change `overrideBaseStyle`.
* Test suite covering the plugin pipeline, individual plugins, the
  controller lifecycle, and a guard against accidental Material/Cupertino
  imports in `lib/`.
* Example app with one screen per feature.
