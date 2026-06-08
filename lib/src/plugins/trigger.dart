import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../plugin.dart';
import '../plugin_context.dart';
import '../styled_range.dart';

/// One option shown in the suggestion popup.
@immutable
class TriggerSuggestion<T> {
  const TriggerSuggestion({
    required this.label,
    required this.value,
    this.subtitle,
    this.leading,
    this.insertText,
    this.data,
  });

  /// The primary text shown in the popup row.
  final String label;

  /// Stable identity for the suggestion.
  final T value;

  /// Optional secondary line (e.g. user handle, command description).
  final String? subtitle;

  /// Optional leading widget (avatar, icon).
  final Widget? leading;

  /// What to substitute into the text. Defaults to [label].
  final String? insertText;

  /// Arbitrary payload returned to [TriggerPlugin.onAccept].
  final Object? data;
}

/// Snapshot of an active trigger session — when the cursor is positioned
/// such that the user is in the middle of typing a triggered expression.
@immutable
class TriggerQuery {
  const TriggerQuery({
    required this.trigger,
    required this.query,
    required this.triggerOffset,
    required this.cursorOffset,
  });

  /// The trigger character itself (e.g. `/`, `@`, `#`).
  final String trigger;

  /// Characters typed *after* the trigger and before the cursor.
  final String query;

  /// Index of the trigger character in the source text.
  final int triggerOffset;

  /// Index of the cursor (selection.extent).
  final int cursorOffset;

  /// Inclusive range covering trigger + query.
  TextRange get range => TextRange(start: triggerOffset, end: cursorOffset);
}

/// Resolves suggestions for an active trigger query. Implementations may
/// be synchronous or asynchronous; for async sources prefer caching.
typedef SuggestionResolver<T> = FutureOr<List<TriggerSuggestion<T>>> Function(
  TriggerQuery query,
);

/// Builds the popup row for a single suggestion. The plugin handles
/// positioning, keyboard navigation, and selection — you only build the
/// row content.
typedef SuggestionItemBuilder<T> = Widget Function(
  BuildContext context,
  TriggerSuggestion<T> suggestion,
  bool selected,
);

/// Builds the overall popup container — the menu surface around the rows.
/// Defaults to a neutral rounded container.
typedef SuggestionMenuBuilder = Widget Function(
  BuildContext context,
  Widget rows,
);

Widget _defaultMenuBuilder(BuildContext context, Widget rows) {
  return Container(
    constraints: const BoxConstraints(maxHeight: 240, minWidth: 180),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0x1F000000)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: rows,
    ),
  );
}

/// Foundation plugin: detects when the user types a configured trigger
/// character and surfaces a suggestion popup. Subclass to wire up a
/// concrete behavior, or instantiate directly with a resolver.
class TriggerPlugin<T> extends InteractiveTextPlugin {
  TriggerPlugin({
    required this.trigger,
    required this.resolver,
    required this.itemBuilder,
    SuggestionMenuBuilder? menuBuilder,
    this.allowedAfter,
    this.queryCharPredicate,
    this.maxQueryLength = 64,
    this.highlightStyle,
    this.priority = 8,
    this.closeOnSpace = false,
    this.allowMultipleTriggers = true,
    this.onAccept,
    this.onClose,
  })  : assert(trigger.length == 1, 'trigger must be a single character'),
        menuBuilder = menuBuilder ?? _defaultMenuBuilder;

  /// The trigger character (e.g. `/`, `@`, `#`).
  final String trigger;

  final SuggestionResolver<T> resolver;
  final SuggestionItemBuilder<T> itemBuilder;
  final SuggestionMenuBuilder menuBuilder;

  /// Optional predicate. If non-null, the trigger only activates when the
  /// character immediately preceding it satisfies the predicate. Default
  /// behavior: activate only at start of text or after whitespace.
  final bool Function(String? precedingChar)? allowedAfter;

  /// Optional predicate that decides whether a character can be part of
  /// the query (between the trigger and the cursor). Default: any
  /// non-newline character is allowed (or any non-whitespace if
  /// [closeOnSpace] is true). Use this to restrict, e.g., mentions to
  /// `[A-Za-z0-9_]+`.
  final bool Function(String ch)? queryCharPredicate;

  /// If the query grows past this many characters without a match, the
  /// popup auto-closes.
  final int maxQueryLength;

  /// Style applied to the matched range (trigger + query) while the popup
  /// is active. Default: no styling.
  final TextStyle? highlightStyle;

  final int priority;

  /// Auto-close as soon as a space is typed. Sensible for slash commands;
  /// generally not for mentions.
  final bool closeOnSpace;

  /// Whether multiple triggers can appear in the same text. Default true.
  final bool allowMultipleTriggers;

  /// Called when the user accepts a suggestion (Tab/Enter/click).
  final void Function(TriggerSuggestion<T> suggestion, TriggerQuery query)?
      onAccept;

  /// Called when the popup closes (programmatic, escape key, focus loss).
  final VoidCallback? onClose;

  TriggerQuery? _active;
  List<TriggerSuggestion<T>> _suggestions = const [];
  int _selectedIndex = 0;
  int _resolverGeneration = 0;
  Offset _anchor = Offset.zero;

  TriggerQuery? get activeQuery => _active;
  List<TriggerSuggestion<T>> get currentSuggestions =>
      List.unmodifiable(_suggestions);
  int get selectedIndex => _selectedIndex;
  bool get isOpen => _active != null;

  @override
  void onSelectionChanged(TextSelection selection) {
    _refresh();
  }

  @override
  void onTextChanged(TextChange change) {
    _refresh();
  }

  void _refresh() {
    final state = context.readEditorState();
    final selection = state.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      _close();
      return;
    }
    final text = state.text;
    final cursor = selection.extent.offset;

    final newActive = _detect(text, cursor);
    if (newActive == null) {
      _close();
      return;
    }
    if (newActive.query.length > maxQueryLength) {
      _close();
      return;
    }
    if (closeOnSpace && newActive.query.contains(' ')) {
      _close();
      return;
    }
    _active = newActive;
    _selectedIndex = 0;
    _resolve(newActive);
    final rect = context.readCaretRect();
    if (rect != null) {
      _anchor = Offset(rect.left, rect.bottom + 4);
    }
    context.requestOverlayRebuild();
  }

  TriggerQuery? _detect(String text, int cursor) {
    if (cursor <= 0 || cursor > text.length) return null;
    int? triggerIndex;
    for (int i = cursor - 1; i >= 0; i--) {
      final ch = text[i];
      if (ch == '\n') return null;
      if (ch == trigger) {
        triggerIndex = i;
        break;
      }
      if (!_isQueryChar(ch)) return null;
    }
    if (triggerIndex == null) return null;
    final precedingChar = triggerIndex == 0 ? null : text[triggerIndex - 1];
    final ok = allowedAfter == null
        ? _defaultAllowedAfter(precedingChar)
        : allowedAfter!(precedingChar);
    if (!ok) return null;
    return TriggerQuery(
      trigger: trigger,
      query: text.substring(triggerIndex + 1, cursor),
      triggerOffset: triggerIndex,
      cursorOffset: cursor,
    );
  }

  bool _defaultAllowedAfter(String? c) {
    if (c == null) return true;
    return c == ' ' || c == '\t' || c == '\n';
  }

  bool _isQueryChar(String ch) {
    if (ch == '\n') return false;
    if (queryCharPredicate != null) return queryCharPredicate!(ch);
    if (closeOnSpace && ch == ' ') return false;
    return true;
  }

  void _resolve(TriggerQuery query) async {
    final gen = ++_resolverGeneration;
    try {
      final result = await resolver(query);
      // After the await the plugin may have been detached. Guard every
      // context access.
      if (!isAttached || gen != _resolverGeneration) return;
      _suggestions = result;
      _selectedIndex = result.isEmpty ? 0 : _selectedIndex.clamp(0, result.length - 1);
      context.requestOverlayRebuild();
    } catch (_) {
      if (!isAttached || gen != _resolverGeneration) return;
      _suggestions = const [];
      context.requestOverlayRebuild();
    }
  }

  void _close() {
    if (_active == null) return;
    _active = null;
    _suggestions = const [];
    _selectedIndex = 0;
    _resolverGeneration++;
    onClose?.call();
    context.requestOverlayRebuild();
  }

  /// Programmatically close the suggestion popup (e.g. on focus loss).
  void close() => _close();

  /// Accept the suggestion currently highlighted in the popup.
  void acceptSelected() {
    final active = _active;
    if (active == null || _suggestions.isEmpty) return;
    final suggestion = _suggestions[_selectedIndex];
    accept(suggestion);
  }

  /// Programmatically accept a specific suggestion.
  ///
  /// If [onAccept] is provided, it's called and the caller is responsible
  /// for any text mutation (giving the embedder full control). Otherwise,
  /// the default behavior is to replace the trigger range (including the
  /// trigger character) with the suggestion's `insertText` (or `label`),
  /// followed by a single space, and place the cursor after.
  void accept(TriggerSuggestion<T> suggestion) {
    final active = _active;
    if (active == null) return;
    if (onAccept != null) {
      onAccept!(suggestion, active);
    } else {
      _defaultApply(active, suggestion);
    }
    _close();
  }

  void _defaultApply(TriggerQuery query, TriggerSuggestion<T> suggestion) {
    final state = context.readEditorState();
    final insert = '${suggestion.insertText ?? suggestion.label} ';
    final before = state.text.substring(0, query.triggerOffset);
    final after = state.text.substring(query.cursorOffset);
    final newText = '$before$insert$after';
    final newOffset = (before.length + insert.length);
    context.writeValue(
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      ),
    );
  }

  void selectNext() {
    if (_suggestions.isEmpty) return;
    _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
    context.requestOverlayRebuild();
  }

  void selectPrevious() {
    if (_suggestions.isEmpty) return;
    _selectedIndex =
        (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
    context.requestOverlayRebuild();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event) {
    if (_active == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      selectNext();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      selectPrevious();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (_suggestions.isNotEmpty &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.tab ||
            key == LogicalKeyboardKey.numpadEnter)) {
      acceptSelected();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  DecorationResult decorate(DecorationContext ctx) {
    final active = _active;
    if (active == null || highlightStyle == null) {
      return const DecorationResult.empty();
    }
    return DecorationResult([
      StyledRange(
        start: active.triggerOffset,
        end: active.cursorOffset,
        style: highlightStyle!,
        priority: priority,
        data: 'trigger:$trigger',
      ),
    ]);
  }

  @override
  Widget? buildOverlay(BuildContext context) {
    if (_active == null || _suggestions.isEmpty) return null;
    return Positioned(
      left: _anchor.dx,
      top: _anchor.dy,
      child: menuBuilder(
        context,
        _SuggestionList<T>(
          suggestions: _suggestions,
          selectedIndex: _selectedIndex,
          itemBuilder: itemBuilder,
          onTap: accept,
        ),
      ),
    );
  }

  @override
  void onDetach() {
    // Bumping the generation makes any in-flight `_resolve` bail at its
    // post-await check instead of touching the now-null PluginContext.
    _resolverGeneration++;
    _active = null;
    _suggestions = const [];
    super.onDetach();
  }
}

class _SuggestionList<T> extends StatelessWidget {
  const _SuggestionList({
    required this.suggestions,
    required this.selectedIndex,
    required this.itemBuilder,
    required this.onTap,
  });

  final List<TriggerSuggestion<T>> suggestions;
  final int selectedIndex;
  final SuggestionItemBuilder<T> itemBuilder;
  final ValueChanged<TriggerSuggestion<T>> onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 232,
        minWidth: 180,
        maxWidth: 320,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemBuilder: (context, index) {
          final s = suggestions[index];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onTap(s),
            child: itemBuilder(context, s, index == selectedIndex),
          );
        },
      ),
    );
  }
}
