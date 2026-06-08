## 0.1.2

### Performance

* `MarkdownPlugin.decorate` no longer re-runs the `_boldItalic` /
  `_bold` regex once per other-emphasis match. Match lists are now
  hoisted once and a linear containment check replaces the previous
  O(N×M) `_overlapsRange`.

### Bulletproofness

* `InteractiveTextFieldState._handleFocusChange` now guards `setState`
  with `mounted` — a focus listener could fire between `dispose`
  removing the listener and Flutter dropping the pending notification.
* `TriggerPlugin` now throws `ArgumentError` instead of `assert`ing when
  given a non-single-character trigger, so the contract holds in
  release builds.

### Versatility

* `MentionPlugin` query characters now accept any Unicode letter / digit
  / underscore (`\p{L}\p{N}_`) instead of ASCII-only — handles in
  non-Latin scripts (CJK, Cyrillic, Arabic, …) now work out of the box.
* `InteractiveTextField` gained three optional pass-throughs:
  `mouseCursor` (defaults to `SystemMouseCursors.text`),
  `cursorOpacityAnimates`, and `forcePressEnabled` (default `true` to
  preserve previous behavior). `MaterialInteractiveTextField` and
  `CupertinoInteractiveTextField` forward all three; Cupertino defaults
  `cursorOpacityAnimates: true` to match native iOS.

## 0.1.1

* **New theme adapters.** `MaterialInteractiveTextField` (import
  `package:interactive_text_field/material.dart`) and
  `CupertinoInteractiveTextField` (import
  `package:interactive_text_field/cupertino.dart`) resolve cursor /
  selection / text style / context menu / selection handles from the
  ambient `ThemeData` or `CupertinoThemeData`. The core library remains
  Material/Cupertino-free; the guard test (`no_material_test.dart`) now
  whitelists the two adapter source files.
* **EffectsPlugin per-range animation.** Pattern matches now animate via
  paint-only properties (color alpha, shadow alpha/blur/offset) — never
  `fontSize`/`fontWeight`/`letterSpacing`, so the surrounding line
  doesn't reflow during animation. New `PatternEffect.appearDuration`
  controls the fade-in; new `PulseEffect` (`colorMin`/`colorMax`,
  `shadowOpacityMin`/`shadowOpacityMax`) drives optional continuous
  pulses. While any range is animating, the plugin ticks itself at
  ~60 fps via a `Timer` and stops when all ranges settle.
* **`Effects.iMessageScale`** rewritten as a 4-tier step function
  (huge / large / medium / normal) so the field's `TweenAnimationBuilder`
  actually animates at each crossing instead of per-character smoothing.
* **`Effects` preset signature changes** — `shouting` / `emojiPop` /
  `numbers` now take optional `appearDuration` + `pulse`. The matched
  style no longer overrides `fontSize` (avoiding the "whole sentence
  wiggles" issue).
* **`InteractiveTextField` animation defaults** — `baseStyleAnimationCurve`
  is now `Curves.easeOutCubic` (was `easeOutBack`, which overshoots) and
  `baseStyleAnimationDuration` is now `220ms` (was `260ms`).

### Bug fixes

* `MarkdownPlugin` — unclosed fenced code blocks now include their final
  character. Previously, when a fence block ended at end-of-text without
  a separator newline (e.g. ``` ```\nbody``` ```), the body's last
  character was dropped.
* `CompletionPlugin._request` and `TriggerPlugin._resolve` now check
  `isAttached` after every `await` and bump their generation counter on
  `onDetach`, so a controller disposed mid-request no longer throws an
  unhandled exception via the now-null `PluginContext`.

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
